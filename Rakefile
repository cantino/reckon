# frozen_string_literal: true

require "bundler/gem_tasks"
require 'rspec/core/rake_task'
require 'English'

RSpec::Core::RakeTask.new(:spec)

task default: :spec

desc "Run specs and integration tests"
task :test_all do
  puts "#{`ledger --version |head -n1`}"
  puts "Running unit tests"
  Rake::Task["spec"].invoke
  puts "Running integration tests"
  Rake::Task["test_integration"].invoke
end

desc "Run integration tests"
task :test_integration do
  cmd = 'prove -v ./spec/integration/test.sh'
  raise 'Integration tests failed' unless system(cmd)
end
