#coding: utf-8
require 'pp'

module Reckon
  class CSVParser 
    attr_accessor :options, :csv_data, :money_column_indices, :date_column_index, :description_column_indices, :money_column

    def initialize(options = {})
      self.options = options
      self.options[:currency] ||= '$'
      parse
      filter_csv
      detect_columns
    end

    def filter_csv
      if options[:ignore_columns]
        new_columns = []
        columns.each_with_index do |column, index|
          new_columns << column unless options[:ignore_columns].include?(index + 1)
        end
        @columns = new_columns
      end
    end

    def money_for(index)
      @money_column[index]
    end

    def pretty_money_for(index, negate = false)
      money_for( index ).pretty( negate )
    end

    def pretty_money(amount, negate = false)
      Money.new( amount, @options ).pretty( negate )
    end

    def date_for(index)
      value = columns[date_column_index][index]
      if options[:date_format].nil?
        value = [$1, $2, $3].join("/") if value =~ /^(\d{4})(\d{2})(\d{2})\d+\[\d+\:GMT\]$/ # chase format
        value = [$3, $2, $1].join("/") if value =~ /^(\d{2})\.(\d{2})\.(\d{4})$/            # german format
        value = [$3, $2, $1].join("/") if value =~ /^(\d{2})\-(\d{2})\-(\d{4})$/            # nordea format
        value = [$1, $2, $3].join("/") if value =~ /^(\d{4})(\d{2})(\d{2})/                 # yyyymmdd format
      else
        begin
          value = Date.strptime(value, options[:date_format])
        rescue
          puts "I'm having trouble parsing #{value} with the desired format: #{options[:date_format]}"
          exit 1
        end
      end
      begin
        guess = Chronic.parse(value, :context => :past)
        if guess.to_i < 953236800 && value =~ /\//
          guess = Chronic.parse((value.split("/")[0...-1] + [(2000 + value.split("/").last.to_i).to_s]).join("/"), :context => :past)
        end
        guess
      rescue
        puts "I'm having trouble parsing #{value}, which I thought was a date.  Please report this so that we"
        puts "can make this parser better!"
      end
    end

    def pretty_date_for(index)
      date_for(index).strftime("%Y/%m/%d")
    end

    def description_for(index)
      description_column_indices.map { |i| columns[i][index] }.join("; ").squeeze(" ").gsub(/(;\s+){2,}/, '').strip
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
          date_score += 30 if entry =~ /^\d+[:\/\.]\d+[:\/\.]\d+([ :]\d+[:\/\.]\d+)?$/
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

      return [results, found_likely_money_column]
    end

    def merge_columns(a, b)
      output_columns = []
      columns.each_with_index do |column, index|
        if index == a
          new_column = []
          column.each_with_index do |row, row_index|
            new_column << row + " " + (columns[b][row_index] || '')
          end
          output_columns << new_column
        elsif index == b
          # skip
        else
          output_columns << column
        end
      end
      output_columns
    end

    def evaluate_two_money_columns( columns, id1, id2, unmerged_results )
      merged_columns = merge_columns( id1, id2 )
      results, found_likely_money_column = evaluate_columns( merged_columns )
      if !found_likely_money_column
        new_res = results.find { |el| el[:index] == id1 }
        old_res1 = unmerged_results.find { |el| el[:index] == id1 }
        old_res2 = unmerged_results.find { |el| el[:index] == id2 }
        if new_res[:money_score] > old_res1[:money_score] &&
          new_res[:money_score] > old_res2[:money_score]
          found_likely_money_column = true
        end
      end
      [results, found_likely_money_column]
    end

    def found_double_money_column( id1, id2 )
      self.money_column_indices = [ id1, id2 ]
      unless settings[:testing]
        puts "It looks like this CSV has two seperate columns for money, one of which shows positive"
        puts "changes and one of which shows negative changes.  If this is true, great.  Otherwise,"
        puts "please report this issue to us so we can take a look!\n"
      end
    end
    
    # Some csv files negative/positive amounts are inicated in separate account
    def detect_sign_column
      # For now only look at preceding column
      return false if @money_column_indices[0] == 0
      column = columns[ @money_column_indices[0] - 1 ]
      signs = column.uniq
      if signs.length == 2
        negative_first = false
        negative_first = true if signs[0] == "Af" || signs[0].downcase =~ /^cr/ # look for known debit indicators
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
      results, found_likely_money_column = evaluate_columns(columns)
      self.money_column_indices = [ results.sort { |a, b| b[:money_score] <=> a[:money_score] }.first[:index] ]

      if !found_likely_money_column
        found_likely_double_money_columns = false
        0.upto(columns.length - 2) do |i|
          if MoneyColumn.new( columns[i] ).merge!( MoneyColumn.new( columns[i+1] ) )
            _, found_likely_double_money_columns = evaluate_columns(merge_columns(i, i+1))
            if found_likely_double_money_columns
              found_double_money_column( i, i + 1 )
              break
            end
          end
        end

        if !found_likely_double_money_columns
          0.upto(columns.length - 2) do |i|
            if MoneyColumn.new( columns[i] ).merge!( MoneyColumn.new( columns[i+1] ) )
              # Try a more specific test
              _, found_likely_double_money_columns = evaluate_two_money_columns( columns, i, i+1, results )
              if found_likely_double_money_columns
                found_double_money_column( i, i + 1 )
                break
              end
            end
          end
        end

        if !found_likely_double_money_columns && !settings[:testing]
          puts "I didn't find a high-likelyhood money column, but I'm taking my best guess with column #{money_column_indices.first + 1}."
        end
      end

      results.reject! {|i| money_column_indices.include?(i[:index]) }
      self.date_column_index = results.sort { |a, b| b[:date_score] <=> a[:date_score] }.first[:index]
      results.reject! {|i| i[:index] == date_column_index }

      if ( money_column_indices.length == 1 )
        @money_column = MoneyColumn.new( columns[money_column_indices[0]],
                                        @options )
        detect_sign_column if @money_column.positive?
      else
        @money_column = MoneyColumn.new( columns[money_column_indices[0]],
                                        @options )
        @money_column.merge!(
          MoneyColumn.new( columns[money_column_indices[1]], @options ) )
      end

      self.description_column_indices = results.map { |i| i[:index] }
    end

    def columns
      @columns ||= begin
        last_row_length = nil
        csv_data.inject([]) do |memo, row|
          # fail "Input CSV must have consistent row lengths." if last_row_length && row.length != last_row_length
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

    def parse
      data = options[:string] || File.read(options[:file])

      if RUBY_VERSION =~ /^1\.9/ || RUBY_VERSION =~ /^2/
        data = data.force_encoding(options[:encoding] || 'BINARY').encode('UTF-8', :invalid => :replace, :undef => :replace, :replace => '?')
        csv_engine = CSV
      else
        csv_engine = FasterCSV
      end

      @csv_data = csv_engine.parse data.strip, :col_sep => options[:csv_separator] || ','
      if options[:contains_header]
        options[:contains_header].times { csv_data.shift }
      end
      csv_data
    end

    @settings = { :testing => false }

    def self.settings
      @settings
    end

    def settings
      self.class.settings
    end
  end
end
