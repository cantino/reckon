# frozen_string_literal: true

module Reckon
  # Singleton class for parsing command line flags
  class Options
    def self.parse_command_line_options(args = ARGV, stdin = $stdin)
      cli = HighLine.new
      options = { output_file: $stdout }
      OptionParser.new do |opts|
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

        opts.on("-l", "--learn-from FILE",
                "An existing ledger file to learn accounts from") do |l|
          options[:existing_ledger_file] = l
        end

        opts.on("", "--ignore-columns 1,2,5",
                "Columns to ignore, starts from 1") do |ignore|
          options[:ignore_columns] = ignore.split(",").map(&:to_i)
        end

        opts.on("", "--money-column 2", Integer,
                "Column number of the money column, starts from 1") do |col|
          options[:money_column] = col
        end

        opts.on("", "--money-columns 2,3",
                "Column number of the money columns, starts from 1 (1 or 2 columns)") do |ignore|
          options[:money_columns] = ignore.split(",").map(&:to_i)
        end

        opts.on("", "--raw-money", "Don't format money column (for stocks)") do |n|
          options[:raw] = n
        end

        opts.on("", "--date-column 3", Integer,
                "Column number of the date column, starts from 1") do |col|
          options[:date_column] = col
        end

        opts.on("", "--contains-header [N]", Integer,
                "Skip N header rows - default 1") do |hdr|
          options[:contains_header] = 1
          options[:contains_header] = hdr.to_i
        end

        opts.on("", "--contains-footer [N]", Integer,
                "Skip N footer rows - default 0") do |hdr|
          options[:contains_footer] = hdr.to_i || 0
        end

        opts.on("", "--csv-separator ','", "CSV separator (default ',')") do |sep|
          options[:csv_separator] = sep
        end

        opts.on("", "--comma-separates-cents",
                "Use comma to separate cents ($100,50 vs. $100.50)") do |c|
          options[:comma_separates_cents] = c
        end

        opts.on("", "--encoding 'UTF-8'", "Specify an encoding for the CSV file") do |e|
          options[:encoding] = e
        end

        opts.on("-c", "--currency '$'",
                "Currency symbol to use - default $ (ex £, EUR)") do |e|
          options[:currency] = e || '$'
        end

        opts.on("", "--date-format FORMAT",
                "CSV file date format (see `date` for format)") do |d|
          options[:date_format] = d
        end

        opts.on("", "--ledger-date-format FORMAT",
                "Ledger date format (see `date` for format)") do |d|
          options[:ledger_date_format] = d
        end

        opts.on("-u", "--unattended",
                "Don't ask questions and guess all the accounts automatically. Use with --learn-from or --account-tokens options.") do |n|
          options[:unattended] = n
        end

        opts.on("-t", "--account-tokens FILE",
                "YAML file with manually-assigned tokens for each account (see README)") do |a|
          options[:account_tokens_file] = a
        end

        opts.on("", "--table-output-file FILE") do |n|
          options[:table_output_file] = n
        end

        options[:default_into_account] = 'Expenses:Unknown'
        opts.on("", "--default-into-account NAME", "Default into account") do |a|
          options[:default_into_account] = a
        end

        options[:default_outof_account] = 'Income:Unknown'
        opts.on("", "--default-outof-account NAME", "Default 'out of' account") do |a|
          options[:default_outof_account] = a
        end

        opts.on("", "--fail-on-unknown-account",
                "Fail on unmatched transactions.") do |n|
          options[:fail_on_unknown_account] = n
        end

        opts.on("", "--suffixed", "Append currency symbol as a suffix.") do |e|
          options[:suffixed] = e
        end

        opts.on("", "--ledger-format FORMAT",
                "Output/Learn format: BEANCOUNT or LEDGER. Default: LEDGER") do |n|
          options[:format] = n
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

      if options[:file] == '-'
        unless options[:unattended]
          raise "--unattended is required to use STDIN as CSV source."
        end

        options[:string] = stdin.read
      end

      unless options[:file]
        options[:file] = cli.ask("What CSV file should I parse? ")
        unless options[:file].empty?
          puts "\nYou must provide a CSV file to parse.\n"
          puts parser
          exit
        end
      end

      unless options[:bank_account]
        raise "Must specify --account in unattended mode" if options[:unattended]

        options[:bank_account] = cli.ask("What is this account named in Ledger?\n") do |q|
          q.readline = true
          q.validate = /^.{2,}$/
          q.default = "Assets:Bank:Checking"
        end
      end

      return options
    end
  end
end
