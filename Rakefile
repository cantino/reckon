# frozen_string_literal: true

require "bundler/gem_tasks"
require 'rspec/core/rake_task'
require 'English'

RSpec::Core::RakeTask.new(:spec)

task :default do
  Rake::Task["spec"].invoke
  Rake::Task["app_tests"].invoke
end

task :app_tests do
  puts "Running integration tests..."
  puts `./spec/integration/test.sh`

  raise 'Integration tests failed' if $CHILD_STATUS.exitstatus != 0
end
