# frozen_string_literal: true

require 'spec_helper'

class TestAlarmJob < ActiveJob::Base; end

class TestAlarmable < ActiveRecord::Base
  include Alarmable

  self.alarm_job = TestAlarmJob
  self.alarm_base_date_property = :start_at
end

class TestAlarmableJobMissing < ActiveRecord::Base
  include Alarmable

  self.alarm_base_date_property = :start_at
end

class TestAlarmableJobInvalid < ActiveRecord::Base
  include Alarmable

  self.alarm_job = :unknown
end

class TestAlarmableBaseDateMissing < ActiveRecord::Base
  include Alarmable

  self.alarm_job = TestAlarmJob
end

class TestAlarmableBaseDateInvalid < ActiveRecord::Base
  include Alarmable

  self.alarm_job = TestAlarmJob
  self.alarm_base_date_property = false
end

tables = %i[test_alarmables
            test_alarmable_job_missings
            test_alarmable_job_invalids
            test_alarmable_base_date_missings
            test_alarmable_base_date_invalids]

RSpec.describe Alarmable do
  include ActiveJob::TestHelper

  def create_tables(*tables)
    tables.each do |table|
      ActiveRecord::Base.connection.create_table table do |t|
        t.jsonb :alarms
        t.jsonb :alarm_jobs
        t.datetime :start_at
      end
    end
  end

  def drop_tables(*tables)
    tables.each do |table|
      ActiveRecord::Base.connection.drop_table table
    end
  end

  # rubocop:disable RSpec/BeforeAfterAll -- because we are aware
  before(:all) { create_tables(*tables) }

  before { enqueued_jobs.clear }

  after(:all) { drop_tables(*tables) }

  let(:alarmable) { TestAlarmable.new(start_at: 1.day.from_now) }
  let(:test_job) { TestAlarmJob.perform_later }
  let(:email_alarm) { { channel: 'email', before_minutes: 15 } }
  let(:alarm_id) { '858dc938829b7a40b31e228f9e7a914d' }
  let(:alarms_attributes) { { alarms: [email_alarm] } }
  let(:alarm_jobs_attributes) do
    { alarm_jobs: { alarm_id => test_job.job_id } }
  end

  let(:uuid_regex) do
    /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/
  end

  it 'has a version number' do
    expect(Alarmable::VERSION).not_to be_nil
  end

  describe '#alarm_id' do
    it 'generates a new alarm id (md5)' do
      expect(alarmable.alarm_id('email', 15).length).to be 32
    end

    it 'generates the same id for the same inputs' do
      expect(alarmable.alarm_id('email', 15)).to eql(alarm_id)
    end

    it 'generates another id for different inputs' do
      expect(alarmable.alarm_id('email', 16)).not_to eql(alarm_id)
    end
  end

  describe '#alarm_job' do
    it 'delivers the alarm job on the instance' do
      expect(alarmable.alarm_job).to eq(TestAlarmable.alarm_job)
    end
  end

  describe '#reschedule_alarm_job' do
    context 'without notification base date' do
      before do
        alarmable.save
        alarmable.update(start_at: nil)
      end

      it 'schedules no new job' do
        expect { alarmable.reschedule_alarm_job(email_alarm) }.not_to \
          change { enqueued_jobs.count }.from(0)
      end

      it 'cancels a older matching job' do
        alarmable.update(alarm_jobs_attributes)
        expect { alarmable.reschedule_alarm_job(email_alarm) }.to \
          change { enqueued_jobs.count }.from(1).to(0)
      end
    end

    context 'with notification date already passed' do
      let(:alarmable) do
        opts = alarms_attributes.merge(start_at: 1.day.ago)
        TestAlarmable.new(opts)
      end

      it 'cancels nothing' do
        test_job
        expect { alarmable.reschedule_alarm_job(email_alarm) }.not_to \
          (change { enqueued_jobs })
      end

      it 'schedules no new jobs' do
        alarmable.reschedule_alarm_job(email_alarm)
        expect(enqueued_jobs).to be_empty
      end
    end

    context 'with notification date not yet passed' do
      before { alarmable.save }

      it 'cancels nothing when no matching job was found' do
        expect(TestAlarmJob).not_to receive(:cancel)
        alarmable.reschedule_alarm_job(email_alarm)
      end

      it 'cancels not non-matching jobs' do
        job_id = test_job.job_id
        alarmable.update_columns(alarm_jobs: { '404' => job_id })
        expect { alarmable.reschedule_alarm_job(email_alarm) }.to \
          change { enqueued_jobs.count }.from(1).to(2)
      end

      it 'cancels matching jobs' do
        job_id = test_job.job_id
        alarmable.update_columns(alarm_jobs: { alarm_id => job_id })
        expect { alarmable.reschedule_alarm_job(email_alarm) }.to \
          (change { enqueued_jobs })
      end

      it 'passes back the partial alarm_job hash' do
        result = alarmable.reschedule_alarm_job(email_alarm)
        expect(result['858dc938829b7a40b31e228f9e7a914d']).to \
          match uuid_regex
      end
    end

    describe 'scheduling of a new alarm job' do
      it 'schedules a new alarm job' do
        expect { alarmable.reschedule_alarm_job(email_alarm) }.to \
          change { enqueued_jobs.count }.from(0).to(1)
      end

      it 'with the persisted entity id' do
        alarmable.save
        alarmable.reschedule_alarm_job(email_alarm)
        expect(enqueued_jobs.last[:args].first).not_to be_nil
      end

      it 'with the entity id set as argument' do
        alarmable.reschedule_alarm_job(email_alarm)
        expect(enqueued_jobs.last[:args].first).to \
          eql(alarmable.id)
      end

      it 'with the alarm set as argument' do
        alarmable.reschedule_alarm_job(email_alarm)
        expect(enqueued_jobs.last[:args].last).to \
          include(email_alarm.stringify_keys)
      end

      it 'with correct schedule date' do
        alarmable.reschedule_alarm_job(email_alarm)
        expect(enqueued_jobs.last[:at]).to \
          eql((alarmable.start_at - 15.minutes).to_f)
      end
    end
  end

  describe '#reschedule_alarm_jobs' do
    before { alarmable.save }

    it 'reschedules every alarm' do
      allow(alarmable).to receive(:reschedule_alarm_job).and_return({})
      expect(alarmable).to receive(:reschedule_alarm_job)
      alarmable.alarms = [email_alarm]
      alarmable.reschedule_alarm_jobs
    end

    it 'cancels nothing on a clean reference pool' do
      expect(TestAlarmJob).not_to receive(:cancel)
      alarmable.alarms = [email_alarm]
      alarmable.alarm_jobs = {}
      alarmable.reschedule_alarm_jobs
    end

    it 'cancels alarms which are not configured anymore' do
      expect(TestAlarmJob).to receive(:cancel).with('404-job-id')
      alarmable.alarms = [email_alarm]
      alarmable.alarm_jobs = { '404' => '404-job-id' }
      alarmable.reschedule_alarm_jobs
    end

    # rubocop:disable RSpec/ExampleLength -- because we need 6 lines here :(
    it 'cancels none updated jobs' do
      allow(alarmable).to receive(:reschedule_alarm_job)
        .and_return({ alarm_id => 'something-new' })
      expect(TestAlarmJob).not_to receive(:cancel).with('404-job-id')
      alarmable.alarms = [email_alarm]
      alarmable.alarm_jobs = { alarm_id => '404-job-id' }
      alarmable.reschedule_alarm_jobs
    end
    # rubocop:enable RSpec/ExampleLength

    it 'updates the alarm_jobs property (persistence)' do
      alarmable.alarms = [email_alarm]
      alarmable.save
      expect { alarmable.reschedule_alarm_jobs }.to \
        (change { alarmable.reload.alarm_jobs })
    end
  end

  describe '#alarms_update_callback' do
    before { alarmable.save }

    it 'only performs rescheduling when alarms was changed' do
      expect(alarmable).to receive(:reschedule_alarm_jobs)
      alarmable.alarms = [email_alarm]
      alarmable.alarms_update_callback
    end

    it 'performs no rescheduling when alarms is untouched' do
      expect(alarmable).not_to receive(:reschedule_alarm_jobs)
      alarmable.alarms_update_callback
    end
  end

  describe '#alarms_destroy_callback' do
    it 'cancels all notification jobs from the reference pool' do
      expect(TestAlarmJob).to receive(:cancel).with('cancel-now')
      alarmable.alarm_jobs = { alarm_id => 'cancel-now' }
      alarmable.alarms_destroy_callback
    end
  end

  describe 'hooks' do
    describe '#alarm_defaults (after_initialize)' do
      it 'sets an empty hash on the alarms property' do
        expect(alarmable.alarms).to eq([])
      end

      it 'sets an empty hash on the alarm_jobs property' do
        expect(alarmable.alarm_jobs).to eq({})
      end
    end

    describe '#validate_alarm_settings (after_initialize)' do
      describe 'alarm_job' do
        it 'raise when not set' do
          expect { TestAlarmableJobMissing.new }.to \
            raise_error(RuntimeError, /alarm_job/)
        end

        # rubocop:disable RSpec/RepeatedExample -- because it looks like the
        #   same but the background is different
        it 'raise not when set' do
          expect { TestAlarmable.new }.not_to raise_error
        end
        # rubocop:enable RSpec/RepeatedExample

        it 'raise when not a class' do
          expect { TestAlarmableJobInvalid.new }.to \
            raise_error(RuntimeError, /alarm_job/)
        end

        # rubocop:disable RSpec/RepeatedExample -- because it looks like the
        #   same but the background is different
        it 'raise not when a class' do
          expect { TestAlarmable.new }.not_to raise_error
        end
        # rubocop:enable RSpec/RepeatedExample
      end

      describe 'alarm_base_date_property' do
        it 'raise when not set' do
          expect { TestAlarmableBaseDateMissing.new }.to \
            raise_error(RuntimeError, /alarm_base_date_property/)
        end

        # rubocop:disable RSpec/RepeatedExample -- because it looks like the
        #   same but the background is different
        it 'raise not when set' do
          expect { TestAlarmable.new }.not_to raise_error
        end
        # rubocop:enable RSpec/RepeatedExample

        it 'raise when not an useable property' do
          expect { TestAlarmableBaseDateInvalid.new }.to \
            raise_error(RuntimeError, /alarm_base_date_property/)
        end

        # rubocop:disable RSpec/RepeatedExample -- because it looks like the
        #   same but the background is different
        it 'raise not when an useable property' do
          expect { TestAlarmable.new }.not_to raise_error
        end
        # rubocop:enable RSpec/RepeatedExample
      end
    end

    describe '#reschedule_alarm_jobs (after_create)' do
      describe 'no alarms change' do
        it 'change not the alarm_jobs' do
          expect { alarmable.save }.not_to \
            (change { alarmable.alarm_jobs })
        end

        it 'creates no new jobs' do
          alarmable.save
          expect(enqueued_jobs).to be_empty
        end
      end

      it 'schedules a new job' do
        alarmable.alarms = [email_alarm]
        expect { alarmable.save }.to \
          change { enqueued_jobs.count }.from(0).to(1)
      end

      it 'changes the alarm_jobs property' do
        alarmable.alarms = [email_alarm]
        expect { alarmable.save }.to \
          (change { alarmable.alarm_jobs })
      end

      it 'schedules no job when base date is nil' do
        alarmable.alarms = [email_alarm]
        alarmable.start_at = nil
        expect { alarmable.save }.not_to \
          change { enqueued_jobs.count }.from(0)
      end
    end

    describe '#alarms_update_callback (before_update)' do
      before { alarmable.save }

      it 'schedules a new job with the correct id' do
        alarmable.update(alarms_attributes)
        expect(enqueued_jobs.last[:args].first).to be >= 1
      end

      it 'schedules no job when base date is nil' do
        opts = alarms_attributes.merge(start_at: nil)
        expect { alarmable.update(opts) }.not_to \
          change { enqueued_jobs.count }.from(0)
      end
    end

    describe '#alarms_destroy_callback (before_destroy)' do
      before { alarmable.save }

      it 'cancels all notification jobs on destroy' do
        alarmable.update(alarms_attributes)
        expect { alarmable.destroy }.to \
          change { enqueued_jobs.count }.from(1).to(0)
      end
    end
  end
  # rubocop:enable RSpec/BeforeAfterAll
end
