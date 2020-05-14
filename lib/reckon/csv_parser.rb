#coding: utf-8

module Reckon
  class CSVParser
    attr_accessor :options, :csv_data, :money_column_indices, :date_column_index, :description_column_indices, :money_column, :date_column

    def initialize(options = {})
      self.options = options
      self.options[:currency] ||= '$'
      @csv_data = parse(options[:string] || File.read(options[:file]), options[:file])
      filter_csv
      detect_columns
    end

    def columns
      @columns ||=
        begin
          last_row_length = nil
          csv_data.inject([]) do |memo, row|
            unless row.all? { |i| i.nil? || i.length == 0 }
              row.each_with_index do |entry, index|
                memo[index] ||= []
                memo[index] << (entry || '').strip
              end
              last_row_length = row.length
            end
            memo
          end
        end
    end

    def date_for(index)
      @date_column.for(index)
    end

    def pretty_date_for(index)
      @date_column.pretty_for( index )
    end

    def money_for(index)
      @money_column[index]
    end

    def pretty_money(amount, negate = false)
      Money.new( amount, @options ).pretty( negate )
    end

    def pretty_money_for(index, negate = false)
      money = money_for(index)
      return 0 if money.nil?

      money.pretty(negate)
    end

    def description_for(index)
      description_column_indices.map { |i| columns[i][index].to_s.strip }
        .reject(&:empty?)
        .join("; ")
        .squeeze(" ")
        .gsub(/(;\s+){2,}/, '')
        .strip
    end

    def row(index)
      csv_data[index].join(", ")
    end

    private

    def filter_csv
      if options[:ignore_columns]
        new_columns = []
        columns.each_with_index do |column, index|
          new_columns << column unless options[:ignore_columns].include?(index + 1)
        end
        @columns = new_columns
      end
    end

    def evaluate_columns(cols)
      results = []
      found_likely_money_column = false
      cols.each_with_index do |column, index|
        money_score = date_score = possible_neg_money_count = possible_pos_money_count = 0
        last = nil
        column.reverse.each_with_index do |entry, row_from_bottom|
          row = csv_data[csv_data.length - 1 - row_from_bottom]
          entry = entry.strip
          money_score += Money::likelihood( entry )
          possible_neg_money_count += 1 if entry =~ /^\$?[\-\(]\$?\d+/
          possible_pos_money_count += 1 if entry =~ /^\+?\$?\+?\d+/
          date_score += 10 if entry =~ /\b(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)/i
          date_score += 5 if entry =~ /^[\-\/\.\d:\[\]]+$/
          date_score += entry.gsub(/[^\-\/\.\d:\[\]]/, '').length if entry.gsub(/[^\-\/\.\d:\[\]]/, '').length > 3
          date_score -= entry.gsub(/[\-\/\.\d:\[\]]/, '').length
          date_score += 30 if entry =~ /^\d+[:\/\.-]\d+[:\/\.-]\d+([ :]\d+[:\/\.]\d+)?$/
          date_score += 10 if entry =~ /^\d+\[\d+:GMT\]$/i

          # Try to determine if this is a balance column
          entry_as_num = entry.gsub(/[^\-\d\.]/, '').to_f
          if last && entry_as_num != 0 && last != 0
            row.each do |row_entry|
              row_entry = row_entry.to_s.gsub(/[^\-\d\.]/, '').to_f
              if row_entry != 0 && last + row_entry == entry_as_num
                 money_score -= 10
                 break
              end
            end
          end
          last = entry_as_num
        end

        if possible_neg_money_count > (column.length / 5.0) && possible_pos_money_count > (column.length / 5.0)
          money_score += 10 * column.length
          found_likely_money_column = true
        end

        results << { :index => index, :money_score => money_score, :date_score => date_score }
      end

      results.sort_by! { |n| -n[:money_score] }

      # check if it looks like a 2-column file with a balance field
      if results.length >= 3 && results[1][:money_score] + results[2][:money_score] >= results[0][:money_score]
        results[1][:is_money_column] = true
        results[2][:is_money_column] = true
      else
        results[0][:is_money_column] = true
      end

      return results.sort_by { |n| n[:index] }
    end

    def found_double_money_column(id1, id2)
      self.money_column_indices = [id1, id2]
      puts "It looks like this CSV has two seperate columns for money, one of which shows positive"
      puts "changes and one of which shows negative changes.  If this is true, great.  Otherwise,"
      puts "please report this issue to us so we can take a look!\n"
    end

    # Some csv files negative/positive amounts are indicated in separate account
    def detect_sign_column
      return if columns[0].length <= 2 # This test needs requires more than two rows otherwise will lead to false positives
      signs = []
      if @money_column_indices[0] > 0
        column = columns[ @money_column_indices[0] - 1 ]
        signs = column.uniq
      end
      if (signs.length != 2 &&
          (@money_column_indices[0] + 1 < columns.length))
        column = columns[ @money_column_indices[0] + 1 ]
        signs = column.uniq
      end
      if signs.length == 2
        negative_first = true
        negative_first = false if signs[0] == "Bij" || signs[0].downcase =~ /^cr/ # look for known debit indicators
        @money_column.each_with_index do |money, i|
          if negative_first && column[i] == signs[0]
            @money_column[i] = -money
          elsif !negative_first && column[i] == signs[1]
            @money_column[i] = -money
          end
        end
      end
    end

    def detect_columns
      results = evaluate_columns(columns)

      if options[:money_column]
        self.money_column_indices = [ options[:money_column] - 1 ]
      else
        self.money_column_indices = results.select { |n| n[:is_money_column] }.map { |n| n[:index] }
        if self.money_column_indices.length == 1
          puts "Using column #{money_column_indices.first + 1} as the money column.  Use --money-colum to specify a different one."
        elsif self.money_column_indices.length == 2
          found_double_money_column(*self.money_column_indices)
        else
          puts "Unable to determine a money column, use --money-column to specify the column reckon should use."
        end
      end

      results.reject! { |i| money_column_indices.include?(i[:index]) }
      if options[:date_column]
        @date_column_index = options[:date_column] - 1
      else
        # sort by highest score followed by lowest index
        @date_column_index = results.max_by { |n| [n[:date_score], -n[:index]] }[:index]
      end
      results.reject! { |i| i[:index] == date_column_index }
      @date_column = DateColumn.new(columns[date_column_index], @options)

      @money_column = MoneyColumn.new(columns[money_column_indices[0]], @options)
      if money_column_indices.length == 1
        detect_sign_column if @money_column.positive?
      else
        @money_column.merge! MoneyColumn.new(columns[money_column_indices[1]], @options)
      end

      self.description_column_indices = results.map { |i| i[:index] }
    end

    def parse(data, filename=nil)
      # Use force_encoding to convert the string to utf-8 with as few invalid characters
      # as possible.
      data.force_encoding(try_encoding(data, filename))
      data = data.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?')
      data.sub!("\xEF\xBB\xBF", '') # strip byte order marker, if it exists

      rows = []
      data.each_line.with_index do |line, i|
        next if i < (options[:contains_header] || 0)
        rows << CSV.parse_line(line, col_sep: options[:csv_separator] || ',')
      end

      rows
    end

    def try_encoding(data, filename = nil)
      encoding = try_encoding_from_file(filename)

      cd = CharDet.detect(data)
      encoding ||= cd['encoding']

      encoding ||= 'BINARY'

      LOGGER.info("suggested file encoding: #{encoding}")

      options[:encoding] || encoding
    end

    def try_encoding_from_file(filename = nil)
      return unless filename

      m = nil
      os = Gem::Platform.local.os
      if os == 'linux'
        m = `file -i #{filename}`.match(/charset=(\S+)/)
      elsif os == 'darwin'
        m = `file -I #{filename}`.match(/charset=(\S+)/)
      end
      m && m[1]
    end
  end
end
