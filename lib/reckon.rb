#!/usr/bin/env ruby

require 'rubygems'
require 'rchardet'
require 'chronic'
require 'csv'
require 'highline/import'
require 'optparse'
require 'terminal-table'
require 'time'
require 'logger'

LOGGER = Logger.new(STDOUT)
LOGGER.level = Logger::ERROR

require_relative('reckon/cosine_similarity')
require File.expand_path(File.join(File.dirname(__FILE__), "reckon", "app"))
require File.expand_path(File.join(File.dirname(__FILE__), "reckon", "ledger_parser"))
require File.expand_path(File.join(File.dirname(__FILE__), "reckon", "csv_parser"))
require File.expand_path(File.join(File.dirname(__FILE__), "reckon", "money"))
