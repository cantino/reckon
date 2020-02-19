# coding: utf-8
require 'pp'
require 'yaml'

module Reckon
  class App
    VERSION = "Reckon 0.4.4"
    attr_accessor :options, :seen, :csv_parser, :regexps, :matcher

    def initialize(options = {})
      LOGGER.level = Logger::INFO if options[:verbose]
      self.options = options
      self.regexps = {}
      self.seen = {}
      self.options[:currency] ||= '$'
      options[:string] = File.read(options[:file]) unless options[:string]
      @csv_parser = CSVParser.new( options )
      @matcher = CosineSimilarity.new(options)
      learn!
    end

    def interactive_output(str)
      return if options[:unattended]
      puts str
    end

    def learn!
      learn_from_account_tokens(options[:account_tokens_file])

      ledger_file = options[:existing_ledger_file]
      return unless ledger_file
      fail "#{ledger_file} doesn't exist!" unless File.exists?(ledger_file)
      learn_from(File.read(ledger_file))
    end

    def learn_from_account_tokens(filename)
      return unless filename

      fail "#{filename} doesn't exist!" unless File.exists?(filename)

      extract_account_tokens(YAML.load_file(filename)).each do |account, tokens|
        tokens.each do |t|
          if t.start_with?('/')
            add_regexp(account, t)
          else
            @matcher.add_document(account, t)
          end
        end
      end
    end

    def learn_from(ledger)
      LedgerParser.new(ledger).entries.each do |entry|
        entry[:accounts].each do |account|
          str = [entry[:desc], account[:amount]].join(" ")
          @matcher.add_document(account[:name], str) unless account[:name] == options[:bank_account]
          pretty_date = entry[:date].iso8601
          seen[pretty_date] ||= {}
          seen[pretty_date][@csv_parser.pretty_money(account[:amount])] = true
        end
      end
    end

    # Add tokens from account_tokens_file to accounts
    def extract_account_tokens(subtree, account = nil)
      if subtree.nil?
        puts "Warning: empty #{account} tree"
        {}
      elsif subtree.is_a?(Array)
        { account => subtree }
      else
        at = subtree.map do |k, v|
          merged_acct = [account, k].compact.join(':')
          extract_account_tokens(v, merged_acct)
        end
        at.inject({}) { |memo, e| memo.merge!(e)}
      end
    end

    def add_regexp(account, regex_str)
      # https://github.com/tenderlove/psych/blob/master/lib/psych/visitors/to_ruby.rb
      match = regex_str.match(/^\/(.*)\/([ix]*)$/m)
      fail "failed to parse regexp #{regex_str}" unless match
      options = 0
      (match[2] || '').split('').each do |option|
        case option
        when 'x' then options |= Regexp::EXTENDED
        when 'i' then options |= Regexp::IGNORECASE
        end
      end
      regexps[Regexp.new(match[1], options)] = account
    end

    def walk_backwards
      seen_anything_new = false
      each_row_backwards do |row|
        interactive_output Terminal::Table.new(:rows => [ [ row[:pretty_date], row[:pretty_money], row[:description] ] ])

        if already_seen?(row)
          interactive_output "NOTE: This row is very similar to a previous one!"
          if !seen_anything_new
            interactive_output "Skipping..."
            next
          end
        else
          seen_anything_new = true
        end

        possible_answers = suggest(row)

        ledger = if row[:money] > 0
          if options[:unattended]
            out_of_account = possible_answers.first || options[:default_outof_account] || 'Income:Unknown'
          else
            out_of_account = ask("Which account provided this income? ([account]/[q]uit/[s]kip) ") { |q|
              q.completion = possible_answers
              q.readline = true
              q.default = possible_answers.first
            }
          end

          finish if out_of_account == "quit" || out_of_account == "q"
          if out_of_account == "skip" || out_of_account == "s"
            interactive_output "Skipping"
            next
          end

          ledger_format( row,
                         [options[:bank_account], row[:pretty_money]],
                         [out_of_account, row[:pretty_money_negated]] )
        else
          if options[:unattended]
            into_account = possible_answers.first || options[:default_into_account] || 'Expenses:Unknown'
          else
            into_account = ask("To which account did this money go? ([account]/[q]uit/[s]kip) ") { |q|
              q.completion = possible_answers
              q.readline = true
              q.default = possible_answers.first
            }
          end
          finish if into_account == "quit" || into_account == 'q'
          if into_account == "skip" || into_account == 's'
            interactive_output "Skipping"
            next
          end

          ledger_format( row,
                         [into_account, row[:pretty_money_negated]],
                         [options[:bank_account], row[:pretty_money]] )
        end

        learn_from(ledger) unless options[:account_tokens_file]
        output(ledger)
      end
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

    def most_specific_regexp_match( row )
      matches = regexps.map { |regexp, account|
        if match = regexp.match(row[:description])
          [account, match[0]]
        end
      }.compact
      matches.sort_by! { |account, matched_text| matched_text.length }.map(&:first)
    end

    def suggest(row)
      most_specific_regexp_match(row) +
        @matcher.find_similar(row[:description]).map { |n| n[:account] }
    end

    def ledger_format(row, line1, line2)
      out = "#{row[:pretty_date]}\t#{row[:description]}\n"
      out += "\t#{line1.first}\t\t\t\t\t#{line1.last}\n"
      out += "\t#{line2.first}\t\t\t\t\t#{line2.last}\n\n"
      out
    end

    def output(ledger_line)
      options[:output_file].puts ledger_line
      options[:output_file].flush
    end

    def already_seen?(row)
      seen[row[:pretty_date]] && seen[row[:pretty_date]][row[:pretty_money]]
    end

    def finish
      options[:output_file].close unless options[:output_file] == STDOUT
      interactive_output "Exiting."
      exit
    end

    def output_table
      output = Terminal::Table.new do |t|
        t.headings = 'Date', 'Amount', 'Description'
        each_row_backwards do |row|
          t << [ row[:pretty_date], row[:pretty_money], row[:description] ]
        end
      end
      interactive_output output
    end

    def self.parse_opts(args = ARGV)
      options = { :output_file => STDOUT }
      parser = OptionParser.new do |opts|
        opts.banner = "Usage: Reckon.rb [options]"
        opts.separator ""

        opts.on("-f", "--file FILE", "The CSV file to parse") do |file|
          options[:file] = file
        end

        opts.on("-a", "--account NAME", "The Ledger Account this file is for") do |a|
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

        opts.on("", "--money-column 2", Integer, "Specify the money column instead of letting Reckon guess - the first column is column 1") do |column_number|
          options[:money_column] = column_number
        end

        opts.on("", "--date-column 3", Integer, "Specify the date column instead of letting Reckon guess - the first column is column 1") do |column_number|
          options[:date_column] = column_number
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

        opts.on("-u", "--unattended", "Don't ask questions and guess all the accounts automatically. Used with --learn-from or --account-tokens options.") do |n|
          options[:unattended] = n
        end

        opts.on("-t", "--account-tokens FILE", "YAML file with manually-assigned tokens for each account (see README)") do |a|
          options[:account_tokens_file] = a
        end

        opts.on("", "--default-into-account NAME", "Default into account") do |a|
          options[:default_into_account] = a
        end

        opts.on("", "--default-outof-account NAME", "Default 'out of' account") do |a|
          options[:default_outof_account] = a
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
        fail "Please specify --account for the unattended mode" if options[:unattended]

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
