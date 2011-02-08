#!/usr/bin/env ruby

require 'rubygems'
if RUBY_VERSION =~ /^1\.9/
  require 'csv'
else
  require 'fastercsv'
end
require 'highline/import'
require 'optparse'
require 'chronic'
require 'time'
require 'terminal-table'

require File.expand_path(File.join(File.dirname(__FILE__), "reckon", "app"))
require File.expand_path(File.join(File.dirname(__FILE__), "reckon", "ledger_parser"))

