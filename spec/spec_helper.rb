# frozen_string_literal: true

require 'simplecov'
SimpleCov.command_name 'specs'

# Test Env
env = ENV['GITHUB_ACTIONS'].nil? ? :test : :github_actions

require 'bundler/setup'
require 'alarmable'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

# Print some information
puts
puts <<DESC
  -------------- Versions --------------
      Active Job: #{ActiveJob.version}
   Active Record: #{ActiveRecord.version}
  Active Support: #{ActiveSupport.version}
  --------------------------------------
DESC
puts

# Configure Active Record
db_config = Pathname.new(__dir__).join('config', 'database.yml')
ActiveRecord::Base.configurations = YAML.load_file(db_config)
ActiveRecord::Base.establish_connection(env)

# Configure Active Job
ActiveJob::Base.queue_adapter = :test
ActiveJob::Base.logger = Logger.new(nil)
