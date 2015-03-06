#coding: utf-8
require 'pp'

module Reckon
  class App
    VERSION = "Reckon 0.3.10"
    attr_accessor :options, :accounts, :tokens, :seen, :csv_parser

    def initialize(options = {})
      self.options = options
      self.tokens = {}
      self.accounts = {}
      self.seen = {}
      self.options[:currency] ||= '$'
      options[:string] = File.read(options[:file]) unless options[:string]
      @csv_parser = CSVParser.new( options )
      learn!
    end

    def learn_from(ledger)
      LedgerParser.new(ledger).entries.each do |entry|
        entry[:accounts].each do |account|
          learn_about_account( account[:name],
                              [entry[:desc], account[:amount]].join(" ") ) unless account[:name] == options[:bank_account]
          seen[entry[:date]] ||= {}
          seen[entry[:date]][@csv_parser.pretty_money(account[:amount])] = true
        end
      end
    end

    def already_seen?(row)
      seen[row[:pretty_date]] && seen[row[:pretty_date]][row[:pretty_money]]
    end

    def learn!
      if options[:existing_ledger_file]
        fail "#{options[:existing_ledger_file]} doesn't exist!" unless File.exists?(options[:existing_ledger_file])
        ledger_data = File.read(options[:existing_ledger_file])
        learn_from(ledger_data)
      end
    end

    def learn_about_account(account, data)
      accounts[account] ||= 0
      tokenize(data).each do |token|
        tokens[token] ||= {}
        tokens[token][account] ||= 0
        tokens[token][account] += 1
        accounts[account] += 1
      end
    end

    def tokenize(str)
      str.downcase.split(/[\s\-]/)
    end

    def walk_backwards
      seen_anything_new = false
      each_row_backwards do |row|
        puts Terminal::Table.new(:rows => [ [ row[:pretty_date], row[:pretty_money], row[:description] ] ])

        if already_seen?(row)
          puts "NOTE: This row is very similar to a previous one!"
          if !seen_anything_new
            puts "Skipping..."
            next
          end
        else
          seen_anything_new = true
        end

        ledger = if row[:money] > 0
          out_of_account = ask("Which account provided this income? ([account]/[q]uit/[s]kip) ") { |q|
            q.readline = true
            q.default = guess_account(row)
          }
          finish if out_of_account == "quit" || out_of_account == "q"
          if out_of_account == "skip" || out_of_account == "s"
            puts "Skipping"
            next
          end

          ledger_format( row,
                         [options[:bank_account], row[:pretty_money]],
                         [out_of_account, row[:pretty_money_negated]] )
        else
          into_account = ask("To which account did this money go? ([account]/[q]uit/[s]kip) ") { |q|
            q.readline = true
            q.default = guess_account(row)
          }
          finish if into_account == "quit" || into_account == 'q'
          if into_account == "skip" || into_account == 's'
            puts "Skipping"
            next
          end

          ledger_format( row,
                         [into_account, row[:pretty_money_negated]],
                         [options[:bank_account], row[:pretty_money]] )
        end

        learn_from(ledger)
        output(ledger)
      end
    end

    def finish
      options[:output_file].close unless options[:output_file] == STDOUT
      puts "Exiting."
      exit
    end

    def output(ledger_line)
      options[:output_file].puts ledger_line
      options[:output_file].flush
    end

    def guess_account(row)
      query_tokens = tokenize(row[:description])

      search_vector = []
      account_vectors = {}

      query_tokens.each do |token|
        idf = Math.log((accounts.keys.length + 1) / ((tokens[token] || {}).keys.length.to_f + 1))
        tf = 1.0 / query_tokens.length.to_f
        search_vector << tf*idf

        accounts.each do |account, total_terms|
          tf = (tokens[token] && tokens[token][account]) ? tokens[token][account] / total_terms.to_f : 0
          account_vectors[account] ||= []
          account_vectors[account] << tf*idf
        end
      end

      # Should I normalize the vectors?  Probably unnecessary due to tf-idf and short documents.

      account_vectors = account_vectors.to_a.map do |account, account_vector|
        { :cosine => (0...account_vector.length).to_a.inject(0) { |m, i| m + search_vector[i] * account_vector[i] },
          :account => account }
      end

      account_vectors.sort! {|a, b| b[:cosine] <=> a[:cosine] }
      account_vectors.first && account_vectors.first[:account]
    end

    def ledger_format(row, line1, line2)
      out = "#{row[:pretty_date]}\t#{row[:description]}\n"
      out += "\t#{line1.first}\t\t\t\t\t#{line1.last}\n"
      out += "\t#{line2.first}\t\t\t\t\t#{line2.last}\n\n"
      out
    end

    def output_table
      output = Terminal::Table.new do |t|
        t.headings = 'Date', 'Amount', 'Description'
        each_row_backwards do |row|
          t << [ row[:pretty_date], row[:pretty_money], row[:description] ]
        end
      end
      puts output
    end

    def each_row_backwards
      rows = []
      (0...@csv_parser.columns.first.length).to_a.each do |index|
        rows << { :date => @csv_parser.date_for(index), 
          :pretty_date => @csv_parser.pretty_date_for(index),
          :pretty_money => @csv_parser.pretty_money_for(index), 
          :pretty_money_negated => @csv_parser.pretty_money_for(index, :negate),
          :money => @csv_parser.money_for(index),
          :description => @csv_parser.description_for(index) }
      end
      rows.sort { |a, b| a[:date] <=> b[:date] }.each do |row|
        yield row
      end
    end

    def self.parse_opts(args = ARGV)
      options = { :output_file => STDOUT }
      parser = OptionParser.new do |opts|
        opts.banner = "Usage: Reckon.rb [options]"
        opts.separator ""

        opts.on("-f", "--file FILE", "The CSV file to parse") do |file|
          options[:file] = file
        end

        opts.on("-a", "--account name", "The Ledger Account this file is for") do |a|
          options[:bank_account] = a
        end

        opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
          options[:verbose] = v
        end

        opts.on("-i", "--inverse", "Use the negative of each amount") do |v|
          options[:inverse] = v
        end

        opts.on("-p", "--print-table", "Print out the parsed CSV in table form") do |p|
          options[:print_table] = p
        end

        opts.on("-o", "--output-file FILE", "The ledger file to append to") do |o|
          options[:output_file] = File.open(o, 'a')
        end

        opts.on("-l", "--learn-from FILE", "An existing ledger file to learn accounts from") do |l|
          options[:existing_ledger_file] = l
        end

        opts.on("", "--ignore-columns 1,2,5", "Columns to ignore in the CSV file - the first column is column 1") do |ignore|
          options[:ignore_columns] = ignore.split(",").map { |i| i.to_i }
        end

        opts.on("", "--contains-header [N]", "The first row of the CSV is a header and should be skipped. Optionally add the number of rows to skip.") do |contains_header|
          options[:contains_header] = 1
          options[:contains_header] = contains_header.to_i if contains_header
        end

        opts.on("", "--csv-separator ','", "Separator for parsing the CSV - default is comma.") do |csv_separator|
          options[:csv_separator] = csv_separator
        end

        opts.on("", "--comma-separates-cents", "Use comma instead of period to deliminate dollars from cents when parsing ($100,50 instead of $100.50)") do |c|
          options[:comma_separates_cents] = c
        end

        opts.on("", "--encoding 'UTF-8'", "Specify an encoding for the CSV file; not usually needed") do |e|
          options[:encoding] = e
        end

        opts.on("-c", "--currency '$'", "Currency symbol to use, defaults to $ (£, EUR)") do |e|
          options[:currency] = e
        end

        opts.on("", "--date-format '%d/%m/%Y'", "Force the date format (see Ruby DateTime strftime)") do |d|
          options[:date_format] = d
        end

        opts.on("", "--suffixed", "If --currency should be used as a suffix. Defaults to false.") do |e|
          options[:suffixed] = e
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
        options[:file] = ask("What CSV file should I parse? ")
        unless options[:file].length > 0
          puts "\nYou must provide a CSV file to parse.\n"
          puts parser
          exit
        end
      end

      unless options[:bank_account]
        options[:bank_account] = ask("What is the account name of this bank account in Ledger? ") do |q|
          q.readline = true
          q.validate = /^.{2,}$/
          q.default = "Assets:Bank:Checking"
        end
      end

      options
    end
  end
end
