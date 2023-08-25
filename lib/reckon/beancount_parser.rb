require 'rubygems'
require 'date'

module Reckon
  class BeancountParser

    attr_accessor :entries

    def initialize(options = {})
      @options = options
      @date_format = options[:ledger_date_format] || options[:date_format] || '%Y-%m-%d'
    end

    # 2015-01-01 * "Opening Balance for checking account"
    #   Assets:US:BofA:Checking                         3490.52 USD
    #   Equity:Opening-Balances                        -3490.52 USD
    
    # input is an object that response to #each_line,
    # (i.e. a StringIO or an IO object)
    def parse(input)
      entries = []
      comment_chars = ';#%*|'
      new_entry = {}

      input.each_line do |entry|

        next if entry =~ /^\s*[#{comment_chars}]/

        m = entry.match(%r{
          ^
          (\d+[\d/-]+)  # date
          \s+
          ([*!])? # type
          \s*
          ("[^"]*")? # description (optional)
          \s*
          ("[^"]*")? # notes (optional)
          # tags (not implemented)
        }x)

        # (date, type, code, description), type and code are optional
        if (m)
          add_entry(entries, new_entry)
          new_entry = {
            date: try_parse_date(m[1]),
            type: m[2] || "",
            desc: trim_quote(m[3]),
            notes: trim_quote(m[4]),
            accounts: []
          }
        elsif entry =~ /^\s*$/ && new_entry[:date]
          add_entry(entries, new_entry)
          new_entry = {}
        elsif new_entry[:date] && entry =~ /^\s+/
          LOGGER.info("Adding new account #{entry}")
          new_entry[:accounts] << parse_account_line(entry)
        else
          LOGGER.info("Unknown entry type: #{entry}")
          add_entry(entries, new_entry)
          new_entry = {}
        end

      end
      entries
    end

    def format_row(row, line1, line2)
      out = %Q{#{row[:pretty_date]} * "#{row[:description]}" "#{row[:note]}"\n}
      out += "\t#{line1.first}\t\t\t#{line1.last}\n"
      out += "\t#{line2.first}\t\t\t#{line2.last}\n\n"
      out
    end

    private

    # remove leading and trailing quote character (")
    def trim_quote(str)
      return str if !str
      str.gsub(/^"([^"]*)"$/, '\1')
    end

    def add_entry(entries, entry)
      return unless entry[:date] && entry[:accounts].length > 1

      entry[:accounts] = balance(entry[:accounts])
      entries << entry
    end

    def try_parse_date(date_str)
      date = Date.parse(date_str)
      return nil if date.year > 9999 || date.year < 1000

      date
    rescue ArgumentError
      nil
    end

    def parse_account_line(entry)
      # TODO handle buying stocks
      #   Assets:US:ETrade:VHT                                 19 VHT {132.32 USD, 2017-08-27}
      (account_name, rest) = entry.strip.split(/\s{2,}|\t+/, 2)

      if rest.nil? || rest.empty?
        return {
          name: account_name,
          amount: clean_money("")
        }
      end
              
      value = if rest =~ /{/
                (qty, dollar_value, date) = rest.split(/[{,]/)
                (qty.to_f * dollar_value.to_f).to_s
              else
                rest
              end

      return {
        name: account_name,
        amount: clean_money(value || "")
      }
    end

    def balance(accounts)
      return accounts unless accounts.any? { |i| i[:amount].nil? }

      sum = accounts.reduce(0) { |m, n| m + (n[:amount] || 0) }
      count = 0
      accounts.each do |account|
        next unless account[:amount].nil?

        count += 1
        account[:amount] = -sum
      end
      if count > 1
        puts "Warning: unparsable entry due to more than one missing money value."
        p accounts
        puts
      end

      accounts
    end

    def clean_money(money)
      return nil if money.nil? || money.empty?

      money.gsub(/[^0-9.-]/, '').to_f
    end
  end
end

