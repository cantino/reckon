# frozen_string_literal: true

require "bundler/gem_tasks"
require 'rspec/core/rake_task'
require 'English'

RSpec::Core::RakeTask.new(:spec)

task :default do
  Rake::Task['app_tests'].invoke
  Rake::Task["spec"].invoke
end

task :app_tests do
  puts "Running integration tests..."
  puts `./spec/app_tests/test.sh`

  raise 'Integration tests failed' if $CHILD_STATUS.exitstatus != 0
end
