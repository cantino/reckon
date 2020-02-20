module Reckon
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
          value = [$1, $2, $3].join("/") if value =~ /^(\d{4})\-(\d{2})\-(\d{2})$/            # yyyy-mm-dd format
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
      guess && guess.to_date
    end

    def pretty_for(index)
      date = self.for(index)
      return "" if date.nil?

      date.iso8601
    end

  end
end
