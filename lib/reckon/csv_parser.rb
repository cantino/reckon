# frozen_string_literal: true

require 'stringio'

module Reckon
  # Parses CSV files
  class CSVParser
    attr_accessor :options, :csv_data, :money_column_indices, :date_column_index,
                  :description_column_indices, :money_column, :date_column

    def initialize(options = {})
      self.options = options

      self.options[:csv_separator] = "\t" if options[:csv_separator] == '\t'
      self.options[:currency] ||= '$'

      # we convert to a string so we can do character encoding cleanup
      @csv_data = parse(options[:string] || File.read(options[:file]), options[:file])
      filter_csv
      detect_columns
    end

    # transpose csv_data (array of rows) to an array of columns
    def columns
      @columns ||= @csv_data[0].zip(*@csv_data[1..])
    end

    def date_for(index)
      @date_column.for(index)
    end

    def pretty_date_for(index)
      @date_column.pretty_for(index)
    end

    def money_for(index)
      @money_column[index]
    end

    def pretty_money(amount, negate = false)
      Money.new(amount, @options).pretty(negate)
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
          entry ||= "" # entries can be nil
          row = csv_data[csv_data.length - 1 - row_from_bottom]
          entry = entry.strip
          money_score += Money::likelihood(entry)
          possible_neg_money_count += 1 if entry =~ /^\$?[\-\(]\$?\d+/
          possible_pos_money_count += 1 if entry =~ /^\+?\$?\+?\d+/
          date_score += DateColumn.likelihood(entry)

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

        results << { :index => index, :money_score => money_score,
                     :date_score => date_score }
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

    # Some csv files negative/positive amounts are indicated in separate account
    def detect_sign_column
      return if columns[0].length <= 2 # This test needs requires more than two rows otherwise will lead to false positives

      signs = []
      if @money_column_indices[0] > 0
        column = columns[@money_column_indices[0] - 1]
        signs = column.uniq
      end
      if (signs.length != 2 &&
          (@money_column_indices[0] + 1 < columns.length))
        column = columns[@money_column_indices[0] + 1]
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

      # We keep money_column options for backwards compatibility reasons, while
      # adding option to specify multiple money_columns
      if options[:money_column]
        self.money_column_indices = [options[:money_column] - 1]

      # One or two columns can be specified as money_columns
      elsif options[:money_columns]
        if options[:money_columns].length == 1
          self.money_column_indices = [options[:money_column] - 1]
        elsif options[:money_columns].length == 2
          in_col, out_col = options[:money_columns]
          self.money_column_indices = [in_col - 1, out_col - 1]
        else
          puts "Unable to determine money columns, use --money-columns to specify the 1 or 2 column(s) reckon should use."
        end

      # If no money_column(s) argument is supplied, try to automatically infer money_column(s)
      else
        self.money_column_indices = results.select { |n|
                                      n[:is_money_column]
                                    }.map { |n| n[:index] }
        if self.money_column_indices.length == 1
          # TODO: print the unfiltered column number, not the filtered
          # ie if money column is 7, but we ignore columns 4 and 5, this prints "Using column 5 as the money column"
          puts "Using column #{money_column_indices.first + 1} as the money column.  Use --money-colum to specify a different one."
        elsif self.money_column_indices.length == 2
          puts "Using columns #{money_column_indices[0] + 1} and #{money_column_indices[1] + 1} as money column. Use --money-columns to specify different ones."
          self.money_column_indices = self.money_column_indices[0..1]
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

    def parse(data, filename = nil)
      # Use force_encoding to convert the string to utf-8 with as few invalid characters
      # as possible.
      data.force_encoding(try_encoding(data, filename))
      data = data.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?')
      data.sub!("\xEF\xBB\xBF", '') # strip byte order marker, if it exists

      separator = options[:csv_separator] || guess_column_separator(data)
      header_lines_to_skip = options[:contains_header] || 0
      # -1 is skip 0 footer rows
      footer_lines_to_skip = (options[:contains_footer] || 0) + 1

      # convert to a stringio object to handle multi-line fields
      parser_opts = {
        col_sep: separator,
        skip_blanks: true
      }
      begin
        rows = CSV.parse(StringIO.new(data), **parser_opts)
        rows[header_lines_to_skip..-footer_lines_to_skip]
      rescue CSV::MalformedCSVError
        # try removing N header lines before parsing
        index = 0
        count = 0
        while count < header_lines_to_skip
          index = data.index("\n", index) + 1 # skip over newline character
          count += 1
        end
        rows = CSV.parse(StringIO.new(data[index..-1]), **parser_opts)
        rows[0..-footer_lines_to_skip]
      end
    end

    def guess_column_separator(data)
      delimiters = [',', "\t", ';', ':', '|']

      counts = [0] * delimiters.length

      data.each_line do |line|
        delimiters.each_with_index do |delim, i|
          counts[i] += line.count(delim)
        end
      end

      LOGGER.info("guessing #{delimiters[counts.index(counts.max)]} as csv separator")

      delimiters[counts.index(counts.max)]
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
