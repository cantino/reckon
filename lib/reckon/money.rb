#coding: utf-8
require 'pp'

module Reckon
  class Money
    attr_accessor :amount
    def initialize( amount )
      @amount = amount.to_f
    end

    def to_f
      return @amount
    end

    def ==( mon )
      to_f == mon.to_f
    end
    
    def pretty( options = {} )
      currency = options[:currency] || "$"
      negate = options[:inverse]
      if options[:suffixed]
        (@amount >= 0 ? " " : "") + sprintf("%0.2f #{currency}", @amount * (negate ? -1 : 1))
      else
        (@amount >= 0 ? " " : "") + sprintf("%0.2f", @amount * (negate ? -1 : 1)).gsub(/^((\-)|)(?=\d)/, "\\1#{currency}")
      end      
    end

    def Money::from_s( value, options = {} )
      value = value.gsub(/\./, '').gsub(/,/, '.') if options[:comma_separates_cents]
      amount = value.gsub(/[^\d\.]/, '').to_f
      amount *= -1 if value =~ /[\(\-]/
      amount = -(cleaned_value) if options[:inverse]
      Money.new( amount )
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
end
 
