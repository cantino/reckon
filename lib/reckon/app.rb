module Reckon
  class App
    VERSION = "Reckon 0.1"

    attr_accessor :options, :csv_data, :accounts, :tokens, :money_column_indices, :date_column_index, :description_column_indices, :seen

    def initialize(options = {})
      self.options = options
      self.tokens = {}
      self.accounts = {}
      self.seen = {}
      learn!
      parse
      filter_csv
      detect_columns
    end

    def filter_csv
      if options[:ignore_columns]
        new_columns = []
        columns.each_with_index do |column, index|
          new_columns << column unless options[:ignore_columns].include?(index + 1)
        end
        @columns = new_columns
      end
    end

    def learn_from(ledger)
      LedgerParser.new(ledger).entries.each do |entry|
        entry[:accounts].each do |account|
          learn_about_account( account[:name],
                               [entry[:desc], account[:amount]].join(" ") ) unless account[:name] == options[:bank_account]
          seen[entry[:date]] ||= {}
          seen[entry[:date]][pretty_money(account[:amount])] = true
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
          out_of_account = ask("Which account provided this income? ([account]/[q]uit/[s]kip) ") { |q| q.default = guess_account(row) }
          finish if out_of_account == "quit" || out_of_account == "q"
          if out_of_account == "skip" || out_of_account == "s"
            puts "Skipping"
            next
          end

          ledger_format( row,
                         [options[:bank_account], row[:pretty_money]],
                         [out_of_account, row[:pretty_money_negated]] )
        else
          into_account = ask("To which account did this money go? ([account]/[q]uit/[s]kip) ") { |q| q.default = guess_account(row) }
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

    def money_for(index)
      value = money_column_indices.inject("") { |m, i| m + columns[i][index] }
      cleaned_value = value.gsub(/[^\d\.]/, '').to_f
      cleaned_value *= -1 if value =~ /[\(\-]/
      cleaned_value
    end

    def pretty_money_for(index, negate = false)
      pretty_money(money_for(index), negate)
    end

    def pretty_money(amount, negate = false)
      (amount >= 0 ? " " : "") + sprintf("%0.2f", amount * (negate ? -1 : 1)).gsub(/^((\-)|)(?=\d)/, '\1$')
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
      output = Terminal::Table.new do |t|
        t.headings = 'Date', 'Amount', 'Description'
        each_row_backwards do |row|
          t << [ row[:pretty_date], row[:pretty_money], row[:description] ]
        end
      end
      puts output
    end

    def evaluate_columns(cols)
      results = []
      found_likely_money_column = false
      cols.each_with_index do |column, index|
        money_score = date_score = possible_neg_money_count = possible_pos_money_count = 0
        column.each do |entry|
          entry = entry.strip
          money_score += 10 if entry[/^[\-\+\(]{0,2}\$/]
          money_score += entry.gsub(/[^\d\.\-\+,\(\)]/, '').length
          money_score -= 100 if entry.length > 17
          money_score -= 20 if entry !~ /^[\$\+\.\-,\d\(\)]+$/
          possible_neg_money_count += 1 if entry =~ /^\$?[\-\(]\$?\d+/
          possible_pos_money_count += 1 if entry =~ /^\+?\$?\+?\d+/
          date_score += 10 if entry =~ /^[\-\/\.\d:\[\]]+$/
          date_score += entry.gsub(/[^\-\/\.\d:\[\]]/, '').length
          date_score -= entry.gsub(/[\-\/\.\d:\[\]]/, '').length * 2
          date_score += 30 if entry =~ /^\d+[:\/\.]\d+[:\/\.]\d+([ :]\d+[:\/\.]\d+)?$/
          date_score += 10 if entry =~ /^\d+\[\d+:GMT\]$/i
        end

        if possible_neg_money_count > (column.length / 5.0) && possible_pos_money_count > (column.length / 5.0)
          money_score += 10 * column.length
          found_likely_money_column = true
        end

        results << { :index => index, :money_score => money_score, :date_score => date_score }
      end

      return [results, found_likely_money_column]
    end

    def merge_columns(a, b)
      output_columns = []
      columns.each_with_index do |column, index|
        if index == a
          new_column = []
          column.each_with_index do |row, row_index|
            new_column << row + " " + columns[b][row_index]
          end
          output_columns << new_column
        elsif index == b
          # skip
        else
          output_columns << column
        end
      end
      output_columns
    end

    def detect_columns
      results, found_likely_money_column = evaluate_columns(columns)

      if found_likely_money_column
        self.money_column_indices = [ results.sort { |a, b| b[:money_score] <=> a[:money_score] }.first[:index] ]
      else
        0.upto(columns.length - 2) do |i|
          _, found_likely_money_column = evaluate_columns(merge_columns(i, i+1))

          if found_likely_money_column
            self.money_column_indices = [ i, i+1 ]
            break
          end
        end
      end

      if money_column_indices
        results.reject! {|i| money_column_indices.include?(i[:index]) }
        self.date_column_index = results.sort { |a, b| b[:date_score] <=> a[:date_score] }.first[:index]
        results.reject! {|i| i[:index] == date_column_index }

        self.description_column_indices = results.map { |i| i[:index] }
      end
    end

    def each_row_backwards
      rows = []
      (0...columns.first.length).to_a.each do |index|
        rows << { :date => date_for(index), :pretty_date => pretty_date_for(index),
                  :pretty_money => pretty_money_for(index), :pretty_money_negated => pretty_money_for(index, :negate),
                  :money => money_for(index), :description => description_for(index) }
      end
      rows.sort { |a, b| a[:date] <=> b[:date] }.each do |row|
        yield row
      end
    end

    def columns
      @columns ||= begin
        last_row_length = nil
        csv_data.inject([]) do |memo, row|
          fail "Input CSV must have consistent row lengths." if last_row_length && row.length != last_row_length
          unless row.all? { |i| i.nil? || i.length == 0 }
            row.each_with_index do |entry, index|
              memo[index] ||= []
              memo[index] << entry.strip
            end
            last_row_length = row.length
          end
          memo
        end
      end
    end

    def parse
      self.csv_data = FasterCSV.parse(options[:string] || File.read(options[:file]))
    end

    def self.parse_opts(args = ARGV)
      options = { :output_file => STDOUT }
      parser = OptionParser.new do |opts|
        opts.banner = "Usage: Reckon.rb [options]"
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

        opts.on("-o", "--output-file FILE", "The ledger file to append to") do |o|
          options[:output_file] = File.open(o, 'a')
        end

        opts.on("-l", "--learn-from FILE", "An existing ledger file to learn accounts from") do |l|
          options[:existing_ledger_file] = l
        end

        opts.on("", "--ignore-columns 1,2,5", "Columns to ignore in the CSV file - the first column is column 1") do |ignore|
          options[:ignore_columns] = ignore.split(",").map { |i| i.to_i }
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
          q.validate = /^.{2,}$/
          q.default = "Assets:Bank:Checking"
        end
      end

      options
    end
  end
end
