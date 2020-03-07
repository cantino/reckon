require 'rubygems'
require 'rspec'
require 'reckon'

RSpec.configure do |config|
  config.before(:all, &:silence_output)
  config.after(:all,  &:enable_output)
  def fixture_path(file)
    File.expand_path(File.join(File.dirname(__FILE__), "data_fixtures", file))
  end
end

public

# Redirects stderr and stout to /dev/null.txt
def silence_output
  # Store the original stderr and stdout in order to restore them later
  @original_stdout = $stdout

  # Redirect stderr and stdout
  $stdout = File.new(File.join(File.dirname(__FILE__), 'test_log.txt'), 'w')
end

# Replace stderr and stdout so anything else is output correctly
def enable_output
  $stdout = @original_stdout
  @original_stdout = nil
end
