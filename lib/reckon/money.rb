#coding: utf-8
require 'pp'

module Reckon
  class Money
    include Comparable
    attr_accessor :amount, :currency, :suffixed
    def initialize( amount, options = {} )
      if options[:inverse]
        @amount = -1*amount.to_f
      else
        @amount = amount.to_f
      end
      @currency = options[:currency] || "$"
      @suffixed = options[:suffixed]
    end

    def to_f
      return @amount
    end

    def -@
      Money.new( -@amount, :currency => @currency, :suffixed => @suffixed )
    end

    def <=>( mon )
      other_amount = mon.to_f
      if @amount < other_amount
        -1
      elsif @amount > other_amount
        1
      else
        0
      end
    end

    def pretty( negate = false )
      if @suffixed
        (@amount >= 0 ? " " : "") + sprintf("%0.2f #{@currency}", @amount * (negate ? -1 : 1))
      else
        (@amount >= 0 ? " " : "") + sprintf("%0.2f", @amount * (negate ? -1 : 1)).gsub(/^((\-)|)(?=\d)/, "\\1#{@currency}")
      end
    end

    def Money::from_s( value, options = {} )
      # Empty string is treated as money with value 0
      return Money.new( 0.00, options ) if value.empty?

      # Remove 1000 separaters and replace , with . if comma_separates_cents
      # 1.000,00 -> 1000.00
      value = value.gsub(/\./, '').gsub(/,/, '.') if options[:comma_separates_cents]
      value = value.gsub(/,/, '')

      money_format_regex = /^(.*?)(\d+\.\d\d)/ # Money has two decimal precision
      any_number_regex = /^(.*?)([\d\.]+)/

      # Prefer matching the money_format, match any number otherwise
      m = value.match( money_format_regex ) ||
        value.match( any_number_regex )
      if m
        amount = m[2].to_f
        # Check whether the money had a - or (, which indicates negative amounts
        if (m[1].match( /^[\(-]/ ) || m[1].match( /-$/  ))
          amount *= -1
        end
        return Money.new( amount, options )
      else
        return nil
      end
    end

    def Money::likelihood( entry )
      money_score = 0
      money_score += 20 if entry[/^[\-\+\(]{0,2}\$/]
      money_score += 10 if entry[/^\$?\-?\$?\d+[\.,\d]*?[\.,]\d\d$/]
      money_score += 10 if entry[/\d+[\.,\d]*?[\.,]\d\d$/]
      money_score += entry.gsub(/[^\d\.\-\+,\(\)]/, '').length if entry.length < 7
      money_score -= entry.length if entry.length > 8
      money_score -= 20 if entry !~ /^[\$\+\.\-,\d\(\)]+$/
      money_score
    end
  end

  class MoneyColumn < Array
    def initialize( arr = [], options = {} )
      arr.each { |str| self.push( Money.from_s( str, options ) ) }
    end

    def positive?
      self.each do |money|
        return false if money < 0 if money
      end
      true
    end

    def merge!( other_column )
      invert = false
      invert = true if self.positive? && other_column.positive?
      self.each_with_index do |mon, i|
        other = other_column[i]
        return nil if (!mon || !other)
        if mon != 0.00 && other == 0.0
          if invert
            self[i]= -mon
          end
        elsif mon == 0.00 && other != 0.00
          self[i] = other
        else
          return nil
        end
      end
      self
    end
  end
end
