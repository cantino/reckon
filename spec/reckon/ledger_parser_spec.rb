#!/usr/bin/env ruby
#encoding: utf-8

require_relative "../spec_helper"
require 'rubygems'
require 'reckon'
require 'pp'
require 'rantly'
require 'rantly/rspec_extensions'
require 'shellwords'

describe Reckon::LedgerParser do
  before do
    @ledger = Reckon::LedgerParser.new(EXAMPLE_LEDGER, date_format: '%Y/%m/%d')
  end

  describe "parse" do
    it "should match ledger csv output" do
      # ledger only parses dates with - or / as separator, and separator is required
      formats = ["%Y/%m/%d", "%Y-%m-%d"]
      types = [' ! ', ' * ', ' ']
      delimiters = ["  ", "\t", "\t\t"]
      comment_chars = ';#%*|'
      currency_delimiters = delimiters + ['']
      currencies = ['', '$', '£']
      property_of do
        Rantly do
          description = Proc.new do
            sized(15){string}.tr(%q{'`:*\\},'').gsub(/\s+/, ' ').gsub(/^[!;<\[( #{comment_chars}]+/, '')
          end
          currency = choose(*currencies) # to be consistent within the transaction
          single_line_comments = ";#|%*".split('').map { |n| "#{n} #{call(description)}" }
          comments = ['', ';   ', "\t;#{call(description)}", "  ; #{call(description)}"]
          date = Time.at(range(0, 1_581_389_644)).strftime(choose(*formats))
          codes = [' ', " (#{string(:alnum).tr('()', '')}) "]
          account = Proc.new { choose(*delimiters) + call(description) }
          account_money = Proc.new do
              sprintf("%.02f", (float * range(5,10) + 1) * choose(1, -1))
          end
          account_line = Proc.new do
            call(account) + \
            choose(*delimiters) + \
            currency + \
            choose(*currency_delimiters) + \
            call(account_money) + \
            choose(*comments)
          end
          ledger = "#{date}#{choose(*types)}#{choose(*codes)}#{call(description)}\n"
          range(1,5).times do
            ledger += "#{call(account_line)}\n"
          end
          ledger += "#{call(account)}\n"
          ledger += choose(*single_line_comments) + "\n"
          ledger
        end
      end.check(1000) do |s|
        filter_format = lambda { |n| [n['date'], n['desc'], n['name'], sprintf("%.02f", n['amount'])] }
        headers = %w[date code desc name currency amount type commend]
        safe_s = Shellwords.escape(s)

        lp_csv = Reckon::LedgerParser.new(s, date_format: '%Y/%m/%d').to_csv.join("\n")
        actual = CSV.parse(lp_csv, headers: headers).map(&filter_format)

        ledger_csv = `echo #{safe_s} | ledger csv --date-format '%Y/%m/%d' -f - `
        expected = CSV.parse(ledger_csv.gsub('\"', '""'), headers: headers).map(&filter_format)
        expected.length.times do |i|
          expect(actual[i]).to eq(expected[i])
        end
      end
    end

    it 'should filter block comments' do
      ledger = <<HERE
1970/11/01 Dinner should show up
  Assets:Checking  -123.00
  Expenses:Restaurants

comment

1970/11/01 Lunch should NOT show up
  Assets:Checking  -12.00
  Expenses:Restaurants

end comment
HERE
      l = Reckon::LedgerParser.new(ledger)
      expect(l.entries.length).to eq(1)
      expect(l.entries.first[:desc]).to eq('Dinner should show up')

    end

    it 'should transaction comments' do
      ledger = <<HERE
2020-03-27      AMZN Mktp USX999H3203; Shopping; Sale
    Expenses:Household                                      $82.77
    Liabilities:ChaseSapphire                                       -$81.77
    # END FINANCE SCRIPT OUTPUT Thu 02 Apr 2020 12:05:54 PM EDT
HERE
      l = Reckon::LedgerParser.new(ledger)
      expect(l.entries.first[:accounts].map { |n| n[:name] }).to eq(['Expenses:Household', 'Liabilities:ChaseSapphire'])
      expect(l.entries.first[:accounts].size).to eq(2)
      expect(l.entries.length).to eq(1)
    end

    it "should ignore non-standard entries" do
      @ledger.entries.length.should == 7
    end

    it "should parse entries correctly" do
      @ledger.entries.first[:desc].should == "Checking balance"
      @ledger.entries.first[:date].should == Date.parse("2004-05-01")
      @ledger.entries.first[:accounts].first[:name].should == "Assets:Bank:Checking"
      @ledger.entries.first[:accounts].first[:amount].should == 1000.00
      @ledger.entries.first[:accounts].last[:name].should == "Equity:Opening Balances"
      @ledger.entries.first[:accounts].last[:amount].should == -1000

      @ledger.entries.last[:desc].should == "Credit card company"
      @ledger.entries.last[:date].should == Date.parse("2004/05/27")
      @ledger.entries.last[:accounts].first[:name].should == "Liabilities:MasterCard"
      @ledger.entries.last[:accounts].first[:amount].should == 20.24
      @ledger.entries.last[:accounts].last[:name].should == "Assets:Bank:Checking"
      @ledger.entries.last[:accounts].last[:amount].should == -20.24
    end
  end

  describe "balance" do
    it "it should balance out missing account values" do
      @ledger.send(:balance, [
          { :name => "Account1", :amount => 1000 },
          { :name => "Account2", :amount => nil }
      ]).should == [ { :name => "Account1", :amount => 1000 }, { :name => "Account2", :amount => -1000 } ]
    end

    it "it should balance out missing account values" do
      @ledger.send(:balance, [
          { :name => "Account1", :amount => 1000 },
          { :name => "Account2", :amount => 100 },
          { :name => "Account3", :amount => -200 },
          { :name => "Account4", :amount => nil }
      ]).should == [
          { :name => "Account1", :amount => 1000 },
          { :name => "Account2", :amount => 100 },
          { :name => "Account3", :amount => -200 },
          { :name => "Account4", :amount => -900 }
      ]
    end

    it "it should work on normal values too" do
      @ledger.send(:balance, [
          { :name => "Account1", :amount => 1000 },
          { :name => "Account2", :amount => -1000 }
      ]).should == [ { :name => "Account1", :amount => 1000 }, { :name => "Account2", :amount => -1000 } ]
    end
  end

  # Data

  EXAMPLE_LEDGER = (<<-LEDGER).strip
= /^Expenses:Books/
  (Liabilities:Taxes)             -0.10

~ Monthly
  Assets:Bank:Checking          $500.00
  Income:Salary

2004-05-01 * Checking balance
  Assets:Bank:Checking        $1,000.00
  Equity:Opening Balances

2004-05-01 * Checking balance
  Assets:Bank:Checking        €1,000.00
  Equity:Opening Balances

2004-05-01 * Checking balance
  Assets:Bank:Checking        1,000.00 SEK
  Equity:Opening Balances

2004/05/01 * Investment balance
  Assets:Brokerage              50 AAPL @ $30.00
  Equity:Opening Balances

; blah
!account blah

!end

D $1,000

2004/05/14 * Pay day
  Assets:Bank:Checking          $500.00
  Income:Salary

2004/05/27 Book Store
  Expenses:Books                 $20.00
  Liabilities:MasterCard
2004/05/27 (100) Credit card company
  Liabilities:MasterCard         $20.24
  Assets:Bank:Checking
  LEDGER
end
