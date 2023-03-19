# frozen_string_literal: true

require 'yaml'
require 'stringio'

module Reckon
  # The main app
  class App
    attr_accessor :options, :seen, :csv_parser, :regexps, :matcher

    def initialize(opts = {})
      self.options = opts
      LOGGER.level = Logger::INFO if options[:verbose]

      self.regexps = {}
      self.seen = Set.new
      @cli = HighLine.new
      @csv_parser = CSVParser.new(options)
      @matcher = CosineSimilarity.new(options)
      @parser = options[:format] =~ /beancount/i ? BeancountParser.new : LedgerParser.new
      learn!
    end

    def interactive_output(str, fh = $stdout)
      return if options[:unattended]

      fh.puts str
    end

    # Learn from previous transactions. Used to recommend accounts for a transaction.
    def learn!
      learn_from_account_tokens(options[:account_tokens_file])
      learn_from_ledger_file(options[:existing_ledger_file])
      # TODO: make this work
      # this doesn't work because output_file is an IO object
      # learn_from_ledger_file(options[:output_file]) if File.exist?(options[:output_file])
    end

    def learn_from_account_tokens(filename)
      return unless filename

      raise "#{filename} doesn't exist!" unless File.exist?(filename)

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

    def learn_from_ledger_file(ledger_file)
      return unless ledger_file

      raise "#{ledger_file} doesn't exist!" unless File.exist?(ledger_file)

      learn_from_ledger(File.new(ledger_file))
    end

    # Takes an IO-like object
    def learn_from_ledger(ledger)
      LOGGER.info "learning from #{ledger}"
      @parser.parse(ledger).each do |entry|
        entry[:accounts].each do |account|
          str = [entry[:desc], account[:amount]].join(" ")
          if account[:name] != options[:bank_account]
            LOGGER.info "adding document #{account[:name]} #{str}"
            @matcher.add_document(account[:name], str)
          end
          pretty_date = entry[:date].iso8601
          if account[:name] == options[:bank_account]
            seen << seen_key(pretty_date, @csv_parser.pretty_money(account[:amount]))
          end
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
        at.inject({}) { |memo, e| memo.merge!(e) }
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
      cmd_options = "[account]/[q]uit/[s]kip/[n]ote/[d]escription"
      seen_anything_new = false
      each_row_backwards do |row|
        print_transaction([row])

        if already_seen?(row)
          interactive_output "NOTE: This row is very similar to a previous one!"
          if !seen_anything_new
            interactive_output "Skipping..."
            next
          end
        else
          seen_anything_new = true
        end

        if row[:money] > 0
          # out_of_account
          answer = ask_account_question(
            "Which account provided this income? (#{cmd_options})", row
          )
          line1 = [options[:bank_account], row[:pretty_money]]
          line2 = [answer, ""]
        else
          # into_account
          answer = ask_account_question(
            "To which account did this money go? (#{cmd_options})", row
          )
          line1 = [answer, ""]
          line2 = [options[:bank_account], row[:pretty_money]]
        end

        finish if %w[quit q].include?(answer)
        if %w[skip s].include?(answer)
          interactive_output "Skipping"
          next
        end

        ledger = @parser.format_row(row, line1, line2)
        LOGGER.info "ledger line: #{ledger}"
        learn_from_ledger(StringIO.new(ledger)) unless options[:account_tokens_file]
        output(ledger)
      end
    end

    def each_row_backwards
      rows = []
      (0...@csv_parser.columns.first.length).to_a.each do |index|
        if @csv_parser.date_for(index).nil?
          LOGGER.warn("Skipping row: '#{@csv_parser.row(index)}' that doesn't have a valid date")
          next
        end
        rows << { :date => @csv_parser.date_for(index),
                  :pretty_date => @csv_parser.pretty_date_for(index),
                  :pretty_money => @csv_parser.pretty_money_for(index),
                  :pretty_money_negated => @csv_parser.pretty_money_for(index, :negate),
                  :money => @csv_parser.money_for(index),
                  :description => @csv_parser.description_for(index) }
      end
      rows.sort_by { |n| [n[:date], -n[:money], n[:description]] }.each { |row| yield row }
    end

    def print_transaction(rows, fh = $stdout)
      str = "\n"
      header = %w[Date Amount Description Note]
      maxes = header.map(&:length)

      rows = rows.map { |r| [r[:pretty_date], r[:pretty_money], r[:description], r[:note]] }

      rows.each do |r|
        r.length.times { |i| l = r[i] ? r[i].length : 0; maxes[i] = l if maxes[i] < l }
      end

      header.each_with_index do |n, i|
        str += " #{n.center(maxes[i])} |"
      end
      str += "\n"

      rows.each do |row|
        row.each_with_index do |_, i|
          just = maxes[i]
          str += sprintf(" %#{just}s |", row[i])
        end
        str += "\n"
      end

      interactive_output str, fh
    end

    def ask_account_question(msg, row)
      possible_answers = suggest(row)
      LOGGER.info "possible_answers===> #{possible_answers.inspect}"

      if options[:unattended]
        if options[:fail_on_unknown_account] && possible_answers.empty?
          raise %(Couldn't find any matches for '#{row[:description]}'
            Try adding an account token with --account-tokens)
        end

        default = options[:default_outof_account]
        default = options[:default_into_account] if row[:pretty_money][0] == '-'
        return possible_answers[0] || default
      end

      answer = @cli.ask(msg) do |q|
        q.completion = possible_answers
        q.readline = true
        q.default = possible_answers.first
      end

      # if answer isn't n/note/d/description, must be an account name, or skip, or quit
      return answer unless %w[n note d description].include?(answer)

      add_description(row) if %w[d description].include?(answer)
      add_note(row) if %w[n note].include?(answer)

      print_transaction([row])
      # give user a chance to set account name or retry description
      return ask_account_question(msg, row)
    end

    def add_description(row)
      desc_answer = @cli.ask("Enter a new description for this transaction (empty line aborts)\n") do |q|
        q.overwrite = true
        q.readline = true
        q.default = row[:description]
      end

      row[:description] = desc_answer unless desc_answer.empty?
    end

    def add_note(row)
      desc_answer = @cli.ask("Enter a new note for this transaction (empty line aborts)\n") do |q|
        q.overwrite = true
        q.readline = true
        q.default = row[:note]
      end

      row[:note] = desc_answer unless desc_answer.empty?
    end

    def most_specific_regexp_match(row)
      matches = regexps.map { |regexp, account|
        if match = regexp.match(row[:description])
          [account, match[0]]
        end
      }.compact
      matches.sort_by { |_account, matched_text| matched_text.length }.map(&:first)
    end

    def suggest(row)
      most_specific_regexp_match(row) +
        @matcher.find_similar(row[:description]).map { |n| n[:account] }
    end

    def output(ledger_line)
      options[:output_file].puts ledger_line
      options[:output_file].flush
    end

    def seen_key(date, amount)
      return [date, amount].join("|")
    end

    def already_seen?(row)
      seen.include?(seen_key(row[:pretty_date], row[:pretty_money]))
    end

    def finish
      options[:output_file].close unless options[:output_file] == STDOUT
      interactive_output "Exiting."
      exit
    end

    def output_table(fh = $stdout)
      rows = []
      each_row_backwards do |row|
        rows << row
      end
      print_transaction(rows, fh)
    end
  end
end
