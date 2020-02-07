require 'rubygems'
require 'rspec'
require 'reckon'

RSpec.configure do |config|
  def fixture_path(file)
    File.expand_path(File.join(File.dirname(__FILE__), "data_fixtures", file))
  end
end
