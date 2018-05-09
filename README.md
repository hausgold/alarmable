![Alarmable](doc/assets/project.png)

[![Build Status](https://travis-ci.org/hausgold/alarmable.svg?branch=master)](https://travis-ci.org/hausgold/alarmable)
[![Gem Version](https://badge.fury.io/rb/alarmable.svg)](https://badge.fury.io/rb/alarmable)
[![Maintainability](https://api.codeclimate.com/v1/badges/f19eedf4a7e280b8f835/maintainability)](https://codeclimate.com/github/hausgold/alarmable/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/f19eedf4a7e280b8f835/test_coverage)](https://codeclimate.com/github/hausgold/alarmable/test_coverage)

This is a reusable alarm concern for Active Record models. It adds support for
the automatic maintenance of Active Job's which are scheduled for the given
alarms. On alarm updates the jobs will be canceled and rescheduled. This is
supported only for Sidekiq, Delayed Job, resque and the Active Job TestAdapter.
(See [ActiveJob::Cancel](https://github.com/y-yagi/activejob-cancel) for the
list of supported adapters)

- [Installation](#installation)
- [Usage](#usage)
  - [Database migration](#database-migration)
  - [Active Record Model](#active-record-model)
  - [Active Job](#active-job)
- [Development](#development)
- [Contributing](#contributing)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'alarmable'
```

And then execute:

```bash
$ bundle
```

Or install it yourself as:

```bash
$ gem install alarmable
```

## Usage

### Database migration

This concern requires the persistence (and availability) of two properties.

* The first is the JSONB array which holds the alarms. (`alarms`)
* The seconds is the JSONB array which holds the ids of the
  scheduled alarm jobs. (`alarm_jobs`)

```bash
$ rails generate migration AddAlarmsAndAlarmJobsToEntity \
  alarms:jsonb alarm_jobs:jsonb
```

### Active Record Model

Furthermore a Active Record model which uses this concern must define the
Active Job class which will be scheduled. (`alarm_job`) The user must also
define the base date property of the owning side.
(`alarm_base_date_property`) This base date is mandatory to calculate the
correct alarm date/time. When the base date is not set (`nil`) no new
notification job will be enqueued. When the base date is unset on an update,
the previously enqueued job will be canceled.

```ruby
# Your Active Record Model
class Entity < ApplicationRecord
  include Alarmable
  self.alarm_job = NotificationJob
  self.alarm_base_date_property = :start_at
end
```

The alarms hash needs to be an array in the following format:

```ruby
[
  {
    "channel": "email",   # email, push, web_notification, etc..
    "before_minutes": 15  # start_at - before_minutes, >= 1

    # [..] you can add custom properties if you like
  }
]
```

### Active Job

The given alarm job class will be scheduled with the following two arguments.

* id - The class/instance id of the record which owns the alarm
* alarm - The alarm hash itself (see the format above)

A suitable alarm job perform method should look like this:

```ruby
# Your notification job
class NotificationJob < ApplicationJob
  # @param id [String] The entity id
  # @param alarm [Hash] The alarm object
  def perform(id, alarm)
    # Do something special for `alarm.channel` ..
  end
end
```

## Development

After checking out the repo, run `make install` to install dependencies. Then,
run `make test` to run the tests. You can also run `make shell-irb` for an
interactive prompt that will allow you to experiment.

To release a new version, update the version number in `version.rb`, and then
run `make release`, which will create a git tag for the version, push git
commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/hausgold/alarmable.
