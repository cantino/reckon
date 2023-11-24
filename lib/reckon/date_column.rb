# frozen_string_literal: true

require 'date'

module Reckon
  # Handle date columns in csv
  class DateColumn < Array
    attr_accessor :endian_precedence

    def initialize(arr = [], options = {})
      # output date format
      @ledger_date_format = options[:ledger_date_format]

      # input date format
      date_format = options[:date_format]
      arr.each do |value|
        if date_format
          begin
            value = Date.strptime(value, date_format)
          # ruby 2.6.0 doesn't have Date::Error, but Date::Error is a subclass of
          # ArgumentError
          rescue ArgumentError
            puts "I'm having trouble parsing '#{value}' with the desired format: #{date_format}"
            exit 1
          end
        else
          value = [$1, $2, $3].join("/") if value =~ /^(\d{4})(\d{2})(\d{2})\d+\[\d+\:GMT\]$/ # chase format
          value = [$3, $2, $1].join("/") if value =~ /^(\d{2})\.(\d{2})\.(\d{4})$/            # german format
          value = [$3, $2, $1].join("/") if value =~ /^(\d{2})\-(\d{2})\-(\d{4})$/            # nordea format
          value = [$1, $2, $3].join("/") if value =~ /^(\d{4})\-(\d{2})\-(\d{2})$/            # yyyy-mm-dd format
          value = [$1, $2, $3].join("/") if value =~ /^(\d{4})(\d{2})(\d{2})/                 # yyyymmdd format

          unless @endian_precedence # Try to detect endian_precedence
            reg_match = value.match(%r{^(\d\d)/(\d\d)/\d\d\d?\d?})
            # If first one is not \d\d/\d\d/\d\d\d?\d set it to default
            if !reg_match
              @endian_precedence = %i[middle little]
            elsif reg_match[1].to_i > 12
              @endian_precedence = [:little]
            elsif reg_match[2].to_i > 12
              @endian_precedence = [:middle]
            end
          end
        end
        push(value)
      end

      # if endian_precedence still nil, raise error
      return if @endian_precedence || date_format

      raise("Unable to determine date format. Please specify using --date-format")
    end

    def for(index)
      value = at(index)
      guess = Chronic.parse(value, contex: :past,
                                   endian_precedence: @endian_precedence)
      if guess.to_i < 953_236_800 && value =~ %r{/}
        guess = Chronic.parse((value.split("/")[0...-1] + [(2000 + value.split("/").last.to_i).to_s]).join("/"), context: :past,
                                                                                                                 endian_precedence: @endian_precedence)
      end
      guess&.to_date
    end

    def pretty_for(index)
      date = self.for(index)
      return "" if date.nil?

      date.strftime(@ledger_date_format || '%Y-%m-%d')
    end

    def self.likelihood(entry)
      date_score = 0
      date_score += 10 if entry =~ /\b(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)/i
      date_score += 5 if entry =~ /^[\-\/\.\d:\[\]]+$/
      # add points for columns that start with date-like characters -/.\d:[]
      date_score += entry.gsub(/[^\-\/\.\d:\[\]]/, '').length if entry.gsub(
        /[^\-\/\.\d:\[\]]/, ''
      ).length > 3
      date_score -= entry.gsub(/[\-\/\.\d:\[\]]/, '').length
      date_score += 30 if entry =~ /^\d+[:\/\.-]\d+[:\/\.-]\d+([ :]\d+[:\/\.]\d+)?$/
      date_score += 10 if entry =~ /^\d+\[\d+:GMT\]$/i

      # ruby 2.6.0 doesn't have Date::Error, but Date::Error is a subclass of
      # ArgumentError
      #
      # Sometimes DateTime.parse can throw a RangeError
      # See https://github.com/cantino/reckon/issues/126
      begin
        DateTime.parse(entry)
        date_score += 20
      rescue StandardError
        # we don't need do anything here since the column didn't parse as a date
        nil
      end

      date_score
    end
  end
end
