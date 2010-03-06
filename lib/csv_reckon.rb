#!/usr/bin/env ruby

require 'rubygems'
require 'fastercsv'
require 'highline/import'
require 'optparse'
require 'time'
require 'terminal-table'

require File.dirname(__FILE__) + "/csv_reckon/app"
require File.dirname(__FILE__) + "/csv_reckon/ledger_parser"

if $0 == __FILE__
  options = CSVReckon::App.parse_opts
  csv_reckon = CSVReckon::App.new(options)

  if options[:print_table]
    csv_reckon.output_table
    exit
  end

  if !csv_reckon.money_column_indices
    puts "I was unable to determine either a single or a pair of combined columns to use as the money column."
    puts "Please pass in the money column index or indices with the command line option --money-column."
    exit
  end

  csv_reckon.walk_backwards
end
