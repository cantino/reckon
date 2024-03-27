# frozen_string_literal: true

# From: https://www.ledger-cli.org/3.0/doc/ledger3.html#Transactions-and-Comments
#
# The ledger file format is quite simple, but also very flexible. It supports many
# options, though typically the user can ignore most of them. They are summarized below.
#
# The initial character of each line determines what the line means, and how it should
# be interpreted. Allowable initial characters are:
#
# NUMBER
#     A line beginning with a number denotes an entry. It may be followed by any
#     number of lines, each beginning with whitespace, to denote the entry's account
#     transactions. The format of the first line is:
#
#     DATE[=EDATE] [*|!] [(CODE)] DESC
#
#     If '*' appears after the date (with optional effective date), it indicates the
#     entry is "cleared", which can mean whatever the user wants it to mean. If '!'
#     appears after the date, it indicates d the entry is "pending"; i.e., tentatively
#     cleared from the user's point of view, but not yet actually cleared. If a 'CODE'
#     appears in parentheses, it may be used to indicate a check number, or the type of
#     the transaction. Following these is the payee, or a description of the
#     transaction.
#
#     The format of each following transaction is:
#
#       ACCOUNT  AMOUNT  [; NOTE]
#
#     The 'ACCOUNT' may be surrounded by parentheses if it is a virtual transactions, or
#     square brackets if it is a virtual transactions that must balance. The 'AMOUNT'
#     can be followed by a per-unit transaction cost, by specifying '@ AMOUNT', or a
#     complete transaction cost with '@@ AMOUNT'. Lastly, the 'NOTE' may specify an
#     actual and/or effective date for the transaction by using the syntax
#     '[ACTUAL_DATE]' or '[=EFFECTIVE_DATE]' or '[ACTUAL_DATE=EFFECtIVE_DATE]'.
# =
#     An automated entry. A value expression must appear after the equal sign.
#
#     After this initial line there should be a set of one or more transactions, just as
#     if it were normal entry. If the amounts of the transactions have no commodity,
#     they will be applied as modifiers to whichever real transaction is matched by the
#     value expression.
# ~
#     A period entry. A period expression must appear after the tilde.
#
#     After this initial line there should be a set of one or more transactions, just as
#     if it were normal entry.
# !
#     A line beginning with an exclamation mark denotes a command directive. It must be
#     immediately followed by the command word. The supported commands are:
#
#     '!include'
#         Include the stated ledger file.
#
#     '!account'
#         The account name is given is taken to be the parent of all transactions that
#         follow, until '!end' is seen.
#
#     '!end'
#         Ends an account block.
#
# ;
#     A line beginning with a colon indicates a comment, and is ignored.
# Y
#     If a line begins with a capital Y, it denotes the year used for all subsequent
#     entries that give a date without a year. The year should appear immediately after
#     the Y, for example: 'Y2004'. This is useful at the beginning of a file, to specify
#     the year for that file. If all entries specify a year, however, this command has
#     no effect.
#
# P
#     Specifies a historical price for a commodity. These are usually found in a pricing
#     history file (see the -Q option). The syntax is:
#
#     P DATE SYMBOL PRICE
#
# N SYMBOL
#     Indicates that pricing information is to be ignored for a given symbol, nor will
#     quotes ever be downloaded for that symbol. Useful with a home currency, such as
#     the dollar ($). It is recommended that these pricing options be set in the price
#     database file, which defaults to ~/.pricedb. The syntax for this command is:
#
#     N SYMBOL
#
# D AMOUNT
#     Specifies the default commodity to use, by specifying an amount in the expected
#     format. The entry command will use this commodity as the default when none other
#     can be determined. This command may be used multiple times, to set the default
#     flags for different commodities; whichever is seen last is used as the default
#     commodity. For example, to set US dollars as the default commodity, while also
#     setting the thousands flag and decimal flag for that commodity, use:
#
#     D $1,000.00
#
# C AMOUNT1 = AMOUNT2
#     Specifies a commodity conversion, where the first amount is given to be equivalent
#     to the second amount. The first amount should use the decimal precision desired
#     during reporting:
#
#     C 1.00 Kb = 1024 bytes
#
# i, o, b, h
#     These four relate to timeclock support, which permits ledger to read timelog
#     files. See the timeclock's documentation for more info on the syntax of its
#     timelog files.

require 'rubygems'

module Reckon
  # Parses ledger files
  class LedgerParser
    # ledger is an object that response to #each_line,
    # (i.e. a StringIO or an IO object)
    def initialize(options = {})
      @options = options
      @date_format = options[:ledger_date_format] || options[:date_format] || '%Y-%m-%d'
    end

    def parse(ledger)
      entries = []
      new_entry = {}
      in_comment = false
      comment_chars = ';#%*|'
      ledger.each_line do |entry|
        entry.rstrip!
        # strip comment lines
        in_comment = true if entry == 'comment'
        in_comment = false if entry == 'end comment'
        next if in_comment
        next if entry =~ /^\s*[#{comment_chars}]/

        # (date, type, code, description), type and code are optional
        if (m = entry.match(%r{^(\d+[^\s]+)\s+([*!])?\s*(\([^)]+\))?\s*(.*)$}))
          add_entry(entries, new_entry)
          new_entry = {
            date: try_parse_date(m[1]),
            type: m[2] || "",
            code: m[3] && m[3].tr('()', '') || "",
            desc: m[4].strip,
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
      add_entry(entries, new_entry)
      entries
    end

    # roughly matches ledger csv format
    def to_csv(ledger)
      return parse(ledger).flat_map do |n|
        n[:accounts].map do |a|
          row = [
            n[:date].strftime(@date_format),
            n[:code],
            n[:desc],
            a[:name],
            "", # currency (not implemented)
            a[:amount],
            n[:type],
            "", # account comment (not implemented)
          ]
          CSV.generate_line(row).strip
        end
      end
    end

    def format_row(row, line1, line2)
      note = row[:note] ? "\t; row[:note]" : ""
      out = "#{row[:pretty_date]}\t#{row[:description]}#{note}\n"
      out += "\t#{line1.first}\t\t\t#{line1.last}\n"
      out += "\t#{line2.first}\t\t\t#{line2.last}\n\n"
      out
    end

    private

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
      (account_name, rest) = entry.strip.split(/\s{2,}|\t+/, 2)

      return {
        name: account_name,
        amount: clean_money("")
      } if rest.nil? || rest.empty?

      (value, _comment) = rest.split(/;/)
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
