#!/usr/bin/env ruby

require 'rubygems'
if RUBY_VERSION =~ /^1\.9/ || RUBY_VERSION =~ /^2/
  require 'csv'
else
  require 'fastercsv'
end
require 'highline/import'
require 'optparse'
require 'chronic'
require 'time'
require 'terminal-table'
require 'charlock_holmes'
require 'pp'

def require_local(file)
  require File.expand_path(File.join(File.dirname(__FILE__), "reckon", file))
end

require_local 'version'
require_local 'app'
require_local 'ledger_parser'
require_local 'classifier'

