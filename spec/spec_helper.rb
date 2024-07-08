# frozen_string_literal: true

require 'simplecov'
SimpleCov.command_name 'specs'

# Test Env
env = ENV['GITHUB_ACTIONS'].nil? ? :test : :github_actions

require 'bundler/setup'
require 'alarmable'
require 'pg'

# Load all support helpers and shared examples
Dir[File.join(__dir__, 'support', '**', '*.rb')].sort.each { |f| require f }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Enable the focus inclusion filter and run all when no filter is set
  # See: http://bit.ly/2TVkcIh
  config.filter_run(focus: true)
  config.run_all_when_everything_filtered = true
end

# Configure Active Record
db_config = Pathname.new(__dir__).join('config', 'database.yml')
load_method = YAML.respond_to?(:unsafe_load) ? :unsafe_load : :load
ActiveRecord::Base.configurations = YAML.send(load_method, db_config.read)
ActiveRecord::Base.establish_connection(env)

# Configure Active Job
ActiveJob::Base.queue_adapter = :test
ActiveJob::Base.logger = Logger.new(nil)
