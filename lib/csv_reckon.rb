#!/usr/bin/env ruby

require 'rubygems'
require 'fastercsv'
require 'highline/import'
require 'optparse'
require 'time'
require 'terminal-table/import'


class CSVReckon
  VERSION = "CSVReckon 0.1"

  attr_accessor :options, :data
  attr_accessor :money_column_index, :date_column_index, :description_column_indices

  def initialize(options = {})
    self.options = options
    parse
    detect_columns
    walk_backwards
  end

  def walk_backwards
    each_index_backwards do |index|
      puts [pretty_date_for(index), pretty_money_for(index), description_for(index)].join("\t")
#      puts ledger_format(index, out_of_account, into_account)
    end
  end

  def ledger_format(index, out_of_account, into_account)
    puts "#{pretty_date_for(index)}\t#{description_for(index)}"
    puts "\t#{into_account}\t\t\t\t\t#{pretty_money_for(index)}"
    puts out_of_account
    puts
  end

  def money_for(index)
    value = columns[money_column_index][index]
    cleaned_value = value.gsub(/[^\d\.]/, '').to_f
    cleaned_value *= -1 if value =~ /[\(\-]/
    cleaned_value
  end

  def pretty_money_for(index)
    sprintf("%0.2f", money_for(index)).gsub(/^((\-)|)(?=\d)/, '\1$')
  end

  def date_for(index)
    value = columns[date_column_index][index]
    value = [$1, $2, $3].join("/") if value =~ /^(\d{4})(\d{2})(\d{2})\d+\[\d+\:GMT\]$/ # chase format
    Time.parse(value)
  end

  def pretty_date_for(index)
    date_for(index).strftime("%Y/%m/%d")
  end

  def description_for(index)
    description_column_indices.map { |i| columns[i][index] }.join("; ").squeeze(" ")
  end

  def output_table
    output = table do |t|
      t.headings = 'Date', 'Amount', 'Description'
      each_index_backwards do |index|
        t << [ { :value => pretty_date_for(index), :alignment => :center },
               { :value => pretty_money_for(index), :alignment => :center },
               description_for(index) ]
      end
    end
    puts output
  end  

  def detect_columns
    results = []
    columns.each_with_index do |column, index|
      money_score = date_score = 0
      column.each do |entry|
        money_score += entry.gsub(/[^\$]/, '').length * 10 + entry.gsub(/[^\d\.\-,\(\)]/, '').length
        money_score -= 20 if entry !~ /^[\$\.\-,\d\(\)]+$/
        date_score += 10 if entry =~ /^[\-\/\.\d:\[\]]+$/
        date_score += entry.gsub(/[^\-\/\.\d:\[\]]/, '').length
        date_score -= entry.gsub(/[\-\/\.\d:\[\]]/, '').length * 2
        date_score += 30 if entry =~ /^\d+[:\/\.]\d+[:\/\.]\d+([ :]\d+[:\/\.]\d+)?$/
        date_score += 10 if entry =~ /^\d+\[\d+:GMT\]$/i
      end
      results << { :index => index, :money_score => money_score, :date_score => date_score }
    end

    self.money_column_index = results.sort { |a, b| b[:money_score] <=> a[:money_score] }.first[:index]
    results.reject! {|i| i[:index] == money_column_index }
    self.date_column_index = results.sort { |a, b| b[:date_score] <=> a[:date_score] }.first[:index]
    results.reject! {|i| i[:index] == date_column_index }

    self.description_column_indices = results.map { |i| i[:index] }
  end

  def each_index_backwards
    (0...columns.first.length).to_a.reverse.each do |index|
      yield index
    end
  end

  def columns
    @columns ||= begin
      last_row_length = nil
      @data.inject([]) do |memo, row|
        fail "Input CSV must have consistent row lengths." if last_row_length && row.length != last_row_length
        row.each_with_index do |entry, index|
          memo[index] ||= []
          memo[index] << entry.strip
        end
        last_row_length = row.length
        memo
      end
    end
  end

  def parse
    self.data = FasterCSV.parse(options[:string] || File.read(options[:file]))
  end

  def self.parse_opts(args = ARGV)
    options = {}
    parser = OptionParser.new do |opts|
      opts.banner = "Usage: csvreckon.rb [options]"
      opts.separator ""

      opts.on("-f", "--file FILE", "The CSV file to parse") do |file|
        options[:file] = file
      end

      opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
        options[:verbose] = v
      end

      opts.on("-p", "--print-table", "Print out the parsed CSV in table form") do |p|
        options[:print_table] = p
      end

      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
      end

      opts.on_tail("--version", "Show version") do
        puts VERSION
        exit
      end

      opts.parse!(args)
    end

    unless options[:file]
      puts "Missing required -f FILE option.\n"
      puts parser
      exit
    end

    options
  end
end

if $0 == __FILE__
  options = CSVReckon.parse_opts
  csv_reckon = CSVReckon.new(options)

  if options[:print_table]
    csv_reckon.output_table
  end
end
