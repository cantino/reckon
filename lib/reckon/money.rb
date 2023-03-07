#coding: utf-8
require 'pp'

module Reckon
  class Money
    include Comparable
    attr_accessor :amount, :currency, :suffixed
    def initialize(amount, options = {})
      @amount_raw = amount
      @raw = options[:raw]

      @amount = parse(amount, options[:comma_separates_cents])
      @amount = -@amount if options[:inverse]
      @currency = options[:currency] || "$"
      @suffixed = options[:suffixed]
    end

    def to_f
      return @amount
    end

    def to_s
      return @raw ? "#{@amount_raw} | #{@amount}" : @amount
    end

    # unary minus
    # ex
    # m = Money.new
    # -m
    def -@
      Money.new(-@amount, :currency => @currency, :suffixed => @suffixed)
    end

    def <=>(mon)
      other_amount = mon.to_f
      if @amount < other_amount
        -1
      elsif @amount > other_amount
        1
      else
        0
      end
    end

    def pretty(negate = false)
      if @raw
        return @amount_raw unless negate

        return @amount_raw[0] == '-' ? @amount_raw[1..-1] : "-#{@amount_raw}"
      end

      amt = pretty_amount(@amount * (negate ? -1 : 1))
      amt = if @suffixed
              "#{amt} #{@currency}"
            else
              amt.gsub(/^((-)|)(?=\d)/, "\\1#{@currency}")
            end

      return (@amount >= 0 ? " " : "") + amt
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

    def pretty_amount(amount)
      sprintf("%0.2f", amount).reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
    end

    def parse(value, comma_separates_cents)
      value = value.to_s
      # Empty string is treated as money with value 0
      return value.to_f if value.to_s.empty?

      invert = value.match(/^\(.*\)$/)
      value = value.gsub(/[^0-9,.-]/, '')
      value = value.tr('.', '').tr(',', '.') if comma_separates_cents
      value = value.tr(',', '')
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
