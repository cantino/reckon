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
      return Money.new( 0.00, options ) if value.empty?
      value = value.gsub(/\./, '').gsub(/,/, '.') if options[:comma_separates_cents]
      value = value.gsub(/,/, '')
      m = value.match( /(\D*)(\d+\.\d\d)(\D*)/ ) || value.match(/^(.*?)([\d\.]+)(\D*)$/)
      if m 
        amount = m[2].to_f
        if (m[1].match( /^-/ ) || m[1].match( /-$/  ))
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

  class DateColumn < Array
    attr_accessor :endian_precedence
    def initialize( arr = [], options = {} )
      arr.each do |value|
        if options[:date_format]
          begin
            value = Date.strptime(value, options[:date_format])
          rescue
            puts "I'm having trouble parsing #{value} with the desired format: #{options[:date_format]}"
            exit 1
          end
        else
          value = [$1, $2, $3].join("/") if value =~ /^(\d{4})(\d{2})(\d{2})\d+\[\d+\:GMT\]$/ # chase format
          value = [$3, $2, $1].join("/") if value =~ /^(\d{2})\.(\d{2})\.(\d{4})$/            # german format
          value = [$3, $2, $1].join("/") if value =~ /^(\d{2})\-(\d{2})\-(\d{4})$/            # nordea format
          value = [$1, $2, $3].join("/") if value =~ /^(\d{4})(\d{2})(\d{2})/                 # yyyymmdd format

          unless @endian_precedence # Try to detect endian_precedence
            reg_match = value.match( /^(\d\d)\/(\d\d)\/\d\d\d?\d?/ )
            # If first one is not \d\d/\d\d/\d\d\d?\d set it to default 
            if !reg_match
              @endian_precedence = [:middle, :little]
            elsif reg_match[1].to_i > 12
              @endian_precedence = [:little]
            elsif reg_match[2].to_i > 12
              @endian_precedence = [:middle]
            end
          end
        end
        self.push( value ) 
      end
      # if endian_precedence still nil, raise error
      unless @endian_precedence || options[:date_format]
        raise( "Unable to determine date format. Please specify using --date-format" )
      end
    end

    def for( index )
      value = self.at( index )
      guess = Chronic.parse(value, :context => :past, 
                            :endian_precedence => @endian_precedence )
      if guess.to_i < 953236800 && value =~ /\//
        guess = Chronic.parse((value.split("/")[0...-1] + [(2000 + value.split("/").last.to_i).to_s]).join("/"), :context => :past, 
                              :endian_precedence => @endian_precedence)
      end
      guess
    end

    def pretty_for(index)
      self.for(index).strftime("%Y/%m/%d")
    end

  end
end

