# frozen_string_literal: true

require "bundler/gem_tasks"
require 'rspec/core/rake_task'
require 'English'

RSpec::Core::RakeTask.new(:spec)

task default: :spec

task :test_all do
  puts "#{`ledger --version |head -n1`}"
  puts "Running unit tests"
  Rake::Task["spec"].invoke
  puts "Running integration tests"
  Rake::Task["integration_tests"].invoke
end

task :integration_tests do
  puts `./spec/integration/test.sh`
  raise 'Integration tests failed' if $CHILD_STATUS.exitstatus != 0
end
