# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'alarmable/version'

Gem::Specification.new do |spec|
  spec.name = 'alarmable'
  spec.version = Alarmable::VERSION
  spec.authors = ['Hermann Mayer']
  spec.email = ['hermann.mayer92@gmail.com']

  spec.license = 'MIT'
  spec.summary = 'A reusable alarm extension to Active Record models'
  spec.description = 'This is a reusable alarm concern for Active Record' \
                     'models. It adds support for the automatic maintenance' \
                     'of Active Job\'s which are scheduled for the given' \
                     'alarms.'

  base_uri = "https://github.com/hausgold/#{spec.name}"
  spec.metadata = {
    'homepage_uri' => base_uri,
    'source_code_uri' => base_uri,
    'changelog_uri' => "#{base_uri}/blob/master/CHANGELOG.md",
    'bug_tracker_uri' => "#{base_uri}/issues",
    'documentation_uri' => "https://www.rubydoc.info/gems/#{spec.name}"
  }

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 3.3'

  spec.add_dependency 'activejob', '>= 7.2'
  spec.add_dependency 'activejob-cancel', '~> 0.3'
  spec.add_dependency 'activerecord', '>= 7.2'
  spec.add_dependency 'activesupport', '>= 7.2'
  spec.add_dependency 'base64', '>= 0.3'
  spec.add_dependency 'bigdecimal', '~> 3.1'
  spec.add_dependency 'hashdiff', '~> 1.0'
  spec.add_dependency 'mutex_m', '>= 0.3'
  spec.add_dependency 'zeitwerk', '~> 2.6'
end
