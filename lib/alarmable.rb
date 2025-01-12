# frozen_string_literal: true

require 'zeitwerk'
require 'active_support'
require 'active_record'
require 'active_job'
require 'active_job/cancel'
require 'hashdiff'

# A reusable alarm extension to Active Record models. It adds support for the
# maintenance of Active Job's (create, update (cancel)) which are schedules
# for the given alarms.  We check for changes on the alarms hash and perform
# updates accordingly.
#
# This concern requires the persistence (and availability) of two properties.
#
# * The first is the JSONB array which holds the alarms. (+alarms+)
# * The seconds is the JSONB array which holds the ids of
#   scheduled alarm jobs. (+alarm_jobs+)
#
#     rails generate migration AddAlarmsAndAlarmJobsToEntity \
#       alarms:jsonb alarm_jobs:jsonb
#
# Furthermore a Active Record model which uses this concern must define the
# Active Job class which will be scheduled. (+alarm_job+) The user must also
# define the base date property of the owning side.
# (+alarm_base_date_property+) This base date is mandatory to calculate the
# correct alarm date/time. When the base date is not set (+nil+) no new
# notification job will be enqueued. When the base date is unset on an
# update, the previously enqueued job will be canceled.
#
# The alarms hash needs to be an array in the following format:
#
#   [
#     {
#       "channel": "email",   # email, push, web_notification, etc..
#       "before_minutes": 15  # start_at - before_minutes, >= 1
#     }
#   ]
#
# The given alarm job class will be scheduled with the following two
# arguments.
#
# * id - The class/instance id of the record which owns the alarm
# * alarm - The alarm hash itself (see the format above)
#
# A suitable alarm job perform method should look like this:
#
#   # @param id [String] The entity id
#   # @param alarm [Hash] The alarm object
#   def perform(id, alarm)
#     # Do something special for +alarm.channel+ ..
#   end
module Alarmable
  # Setup a Zeitwerk autoloader instance and configure it
  loader = Zeitwerk::Loader.for_gem

  # Finish the auto loader configuration
  loader.setup

  # Make sure to eager load all SDK constants
  loader.eager_load

  extend ActiveSupport::Concern

  class_methods do
    # Getter/Setter
    #
    # :reek:Attribute because thats what this thing is about
    attr_accessor :alarm_job, :alarm_base_date_property
  end

  # rubocop:disable Metrics/BlockLength because Active Support like it
  included do
    # Hooks
    after_initialize :validate_alarm_settings, :alarm_defaults

    # Here comes a little cheat sheet when and what action is performed
    # on the alarm jobs.
    #
    # create  |              [            time check, reschedule]
    # update  | dirty check, [cancel job, time check, reschedule]
    # destroy |              [cancel job                        ]
    after_create :reschedule_alarm_jobs
    before_update :alarms_update_callback
    before_destroy :alarms_destroy_callback

    # Getter for the alarm job class.
    #
    # @return [Class] The alarm job class
    def alarm_job
      self.class.alarm_job
    end

    # Getter for the alarm base date property.
    #
    # @return [Symbol] The user defined base date property
    def alarm_base_date_property
      self.class.alarm_base_date_property
    end

    # Set some defaults on the relevant alarm properties.
    def alarm_defaults
      self.alarms ||= []
      self.alarm_jobs ||= {}
    end

    # Validate the presence of the +alarm_job+ property and the accessibility
    # of the specified class. Also validate the +alarm_base_date_property+
    # setting.
    #
    # rubocop:disable Style/GuardClause because its fine like this
    # :reek:NilCheck because we validate concern usage
    def validate_alarm_settings
      raise 'Alarmable +alarm_job+ is not configured' if alarm_job.nil?
      unless alarm_job.is_a? Class
        raise 'Alarmable +alarm_job+ is not instantiable'
      end
      if alarm_base_date_property.nil?
        raise 'Alarmable +alarm_base_date_property+ is not configured'
      end
      unless has_attribute? alarm_base_date_property
        raise 'Alarmable +alarm_base_date_property+ is not usable'
      end
    end
    # rubocop:enable Style/GuardClause

    # Generate a unique and recalculatable identifier for a given alarm
    # object.  We build a hash of the primary keys (before_minutes and
    # channel) to achive this.  Afterwards, this alarm id is used to
    # reference dedicated scheduled jobs and track their updates. (Or cancel
    # them accordingly)
    #
    # @param channel [String] The alarm channel
    # @param before_minutes [Integer] The minutes before the alarm starts
    # @return [String] The unique alarm id
    #
    # :reek:UtilityFunction because its a utility, for sure
    def alarm_id(channel, before_minutes)
      (Digest::MD5.new << "#{channel}#{before_minutes}").to_s
    end

    # Schedule a new Active Job for the alarm notification. This method takes
    # care of the notification time (+date) and will not touch anything when
    # the desired time already passed.  It cancels the correct job for the
    # given combination, when it is present. In the end it schedules a new
    # (renewed) job for the given alarm settings.
    #
    # @param alarm [Hash] The alarm object
    # @return [Object] The new alarm_jobs instance (partial)
    #   Example: { "alarm id": "job id" }
    #
    # rubocop:disable Metrics/AbcSize because its already broken down
    # :reek:TooManyStatements because see above
    # :reek:NilCheck because we dont want to cancel 'nil' job id
    # :reek:DuplicateMethodCall because hash access is fast
    def reschedule_alarm_job(alarm)
      # Symbolize the hash keys (just to be sure).
      alarm = alarm.symbolize_keys

      # Calculate the alarm id for job canceling and cancel a found job.
      id = alarm_id(alarm[:channel], alarm[:before_minutes])
      previous_job_id = alarm_jobs.try(:[], id)
      alarm_job.cancel(previous_job_id) unless previous_job_id.nil?

      base_date = self[alarm_base_date_property]

      # When the base date is not set, we schedule not a new notification job.
      return {} if base_date.nil?

      # Calculate the time when the job should run.
      notify_at = base_date - alarm[:before_minutes].minutes

      # Do nothing when the notification date already passed.
      return {} if Time.current >= notify_at

      # Put a new job to the queue with the new (current) job execution date.
      job = alarm_job.set(wait_until: notify_at).perform_later(self.id, alarm)

      # Construct a new alarm_jobs partial instance for this job
      { id => job.job_id }
    end
    # rubocop:enable Metrics/AbcSize

    # Initiate a reschedule for each alarm in the alarm settings and
    # cancel all left-overs.
    #
    # :reek:TooManyStatements because its already broken down
    def reschedule_alarm_jobs
      # Perform the reschedule of all the current alarms.
      new_alarm_jobs = alarms.each_with_object({}) do |alarm, memo|
        memo.merge!(reschedule_alarm_job(alarm))
      end

      # Detect the differences from the original alarm_jobs hash to the new
      # built (by partials) alarm_jobs hash. The jobs from negative
      # differences must be canceled.
      diff = Hashdiff.diff(alarm_jobs, new_alarm_jobs)

      diff.select { |prop| prop.first == '-' }.each do |prop|
        alarm_job.cancel(prop.last)
      end

      # Update the alarm_jobs reference pool with our fresh hash.  Bypass the
      # regular validation and callbacks here, this is required to not stuck
      # in endless create-update loops.
      update_columns(alarm_jobs: new_alarm_jobs)
    end

    # Reschedule only on updates when the alarm settings are changed.
    def alarms_update_callback
      reschedule_alarm_jobs if alarms_changed?
    end

    # Cancel all alarm notification jobs on parent destroy.
    def alarms_destroy_callback
      alarm_jobs.each_value { |job_id| alarm_job.cancel(job_id) }
    end
  end
  # rubocop:enable Metrics/BlockLength
end
