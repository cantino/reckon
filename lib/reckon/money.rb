# frozen_string_literal: true

# Money in reckon has 3 characteristics
# - representation (amount)
# - value
# - currency

# value is used for mathematical transformations and comparisons (adding, subtracting, balancing, etc)
# representation is how the money is displayed, for stocks it's the stocks and the price paid
# currency is currency symbol ($) or currency code (USD)

#### QUESTIONS
# Why am I doing all this?  Just so I get Fidelity, which I decided not to import anymore anyway?
# Should ledger/hledger be used to parse the ledger file reckon learns from?

module Reckon
  class Money
    include Comparable
    attr_accessor :amount, :currency, :suffixed

    def initialize(amount, options = {})
      @options = options

      (@currency, @amount) = parse(amount)

      @value = val(@amount, options)
      if options[:inverse]
        @amount = -@value
        @value = -@value
      end
      @currency = options[:currency] if options[:currency]
      @suffixed = options[:suffixed]
    end

    def to_f
      return @value
    end

    def to_s
      return @amount
    end

    def to_h
      { amount: @amount, currency: @currency, value: @value }
    end

    # unary minus
    # ex
    # m = Money.new
    # -m
    # This is broken for securities
    def -@
      Money.new(-@value, currency: @currency, suffixed: @suffixed)
    end

    def <=>(other)
      @value <=> other.to_f
    end

    def pretty(negate = false)
      return [@amount, @currency].reject(&:empty?).join ' ' if @suffixed
      return "-#{@currency}#{@amount[1..]}" if @value.negative? || negate
      return "#{@currency}#{@amount}"
    end

    def self.likelihood(entry)
      money_score = 0
      # digits separated by , or . with no more than 2 trailing digits
      money_score += 40 if entry.match(/\d+[,.]\d{2}[^\d]*$/)
      money_score += 10 if entry[/^\$?\-?\$?\d+[\.,\d]*?[\.,]\d\d$/]
      money_score += 10 if entry[/\d+[\.,\d]*?[\.,]\d\d$/]
      money_score += entry.gsub(/[^\d\.\-\+,\(\)]/, '').length if entry.length < 7
      money_score -= entry.length if entry.length > 12
      money_score -= 20 if (entry !~ /^[\$\+\.\-,\d\(\)]+$/) && entry.length > 0
      money_score
    end

    private

    # Try to parse a string value into an amount and a currency
    def parse(value)
      digits = '0-9,.-'

      value = format("%0.2f", value) unless value.is_a? String
      invert = ''
      if value.match(/^\(.*\)$/)
        value = value.tr('()', '')
        invert = '-'
      end

      # Empty string is treated as money with value 0
      return ['', '0'] if value.empty?

      # no currency
      # 100.00
      if (m = value.match(/^\s*([#{digits}]+)+\s*$/))
        return ['', invert + m[1]]
      end

      # prefixed currency
      # $100.00
      if (m = value.match(/^\s*(-)?\s*([^ #{digits}]{1,3})\s*([#{digits}]+)\s*$/))
        return [m[2], invert + m[1].to_s + m[3]]
      end

      # suffixed currency
      # 100.00 USD
      if (m = value.match(/^\s*([#{digits}]+)\s*([^ #{digits}]{1,3})\s*$/))
        return [m[2], invert + m[1]]
      end

      # default, possibly something like
      # 0.360 VFIAX @297.39
      return ['', value]
    end

    def val(value, options = {})
      value = value.tr('.', '').tr(',', '.') if options[:comma_separates_cents]
      value = value.tr(',', '')

      # if it looks like a security line
      if (m = value.match /([0-9.-]+)[^@]+@([0-9.-]+)/)
        return m[1].to_f * m[2].to_f
      end

      # parens is used as negative value
      invert = value.match(/^\(.*\)$/)
      value = value.gsub(/[^0-9,.-]/, '')
      value = value.to_f
      return invert ? -value : value
    end
  end

  class MoneyColumn < Array
    def initialize(arr = [], options = {})
      arr.each { |str| push(Money.new(str, options)) }
    end

    def positive?
      each do |money|
        return false if money && money < 0
      end
      true
    end

    def merge!(other_column)
      invert = false
      invert = true if positive? && other_column.positive?
      each_with_index do |mon, i|
        other = other_column[i]
        return nil if !mon || !other

        if mon != 0.0 && other == 0.0
          self[i] = -mon if invert
        elsif mon == 0.0 && other != 0.0
          self[i] = other
        else
          self[i] = Money.new(0)
        end
      end
      self
    end
  end
end
