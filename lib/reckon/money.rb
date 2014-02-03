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
      return nil if value.empty?
      value = value.gsub(/\./, '').gsub(/,/, '.') if options[:comma_separates_cents]
      amount = value.gsub(/[^\d\.]/, '').to_f
      amount *= -1 if value =~ /[\(\-]/
      Money.new( amount, options )
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
        if mon && !other
          if invert
            self[i]= -mon
          end
        elsif !mon && other
          self[i] = other
        else
          return nil
        end
      end
      self
    end
  end

  class DateColumn < Array
    def initialize( arr = [], options = {} )
    end
    def guess
      nil
    end
  end

end

