#!/usr/bin/env ruby

require "spec_helper"
require 'rubygems'
require 'reckon'

describe Reckon::App do
  context 'with chase csv input' do
    before do
      @chase = Reckon::App.new(string: BANK_CSV)
      @chase.learn_from_ledger(BANK_LEDGER)
      @rows = []
      @chase.each_row_backwards { |row| @rows.push(row) }
    end

    describe "each_row_backwards" do
      it "should return rows with hashes" do
        @rows[0][:pretty_date].should == "2009-12-10"
        @rows[0][:pretty_money].should == " $2,105.00"
        @rows[0][:description].should == "CREDIT; Some Company vendorpymt PPD ID: 5KL3832735"
        @rows[1][:pretty_date].should == "2009-12-11"
        @rows[1][:pretty_money].should == " $116.22"
        @rows[1][:description].should == "CREDIT; PAYPAL TRANSFER PPD ID: PAYPALSDSL"
      end
    end

    describe "weighted_account_match" do
      it "should guess the correct account" do
        row = @rows.find { |n| n[:description] =~ /Book Store/ }

        result = @chase.matcher.find_similar(row[:description]).first
        expect(result[:account]).to eq("Expenses:Books")
        expect(result[:similarity]).to be > 0.0
      end
    end
  end

  context 'unattended mode with chase csv input' do
    let(:output_file) { StringIO.new }
    let(:chase) do
      Reckon::App.new(
        string: BANK_CSV,
        unattended: true,
        output_file: output_file,
        bank_account: 'Assets:Bank:Checking',
        default_into_account: 'Expenses:Unknown',
        default_outof_account: 'Income:Unknown',
      )
    end

    describe 'walk backwards' do
      it 'should assign Income:Unknown and Expenses:Unknown by default' do
        chase.walk_backwards
        expect(output_file.string.scan('Expenses:Unknown').count).to eq(5)
        expect(output_file.string.scan('Income:Unknown').count).to eq(4)
      end

      it 'should change default account names' do
        chase = Reckon::App.new(
          string: BANK_CSV,
          unattended: true,
          output_file: output_file,
          default_into_account: 'Expenses:Default',
          default_outof_account: 'Income:Default',
          bank_account: 'Assets:Bank:Checking',
        )
        chase.walk_backwards
        expect(output_file.string.scan('Expenses:Default').count).to eq(5)
        expect(output_file.string.scan('Income:Default').count).to eq(4)
      end

      it 'should learn from a ledger file' do
        chase.learn_from_ledger(BANK_LEDGER)
        chase.walk_backwards
        output_file.string.scan('Expenses:Books').count.should == 1
      end

      it 'should learn from an account tokens file and parse regexps' do
        chase = Reckon::App.new(
          string: BANK_CSV,
          unattended: true,
          output_file: output_file,
          account_tokens_file: fixture_path('tokens.yaml'),
          bank_account: 'Assets:Bank:Checking',
        )
        chase.walk_backwards
        expect(output_file.string.scan('Expenses:Books').count).to eq(1)
        expect(output_file.string.scan('Expenses:Websites').count).to eq(2)
      end
    end

    it 'should fail-on-unknown-account' do
      chase = Reckon::App.new(
        string: BANK_CSV,
        unattended: true,
        output_file: output_file,
        bank_account: 'Assets:Bank:Checking',
        default_into_account: 'Expenses:Unknown',
        default_outof_account: 'Income:Unknown',
        fail_on_unknown_account: true
      )

      expect { chase.walk_backwards }.to(
        raise_error(RuntimeError, /Couldn't find any matches/)
      )
    end
  end

  context "Issue #73 - regression test" do
    it "should categorize transaction correctly" do
      output = StringIO.new
      app = Reckon::App.new(
        file: fixture_path('73-sample.csv'),
        unattended: true,
        account_tokens_file: fixture_path('73-tokens.yml'),
        bank_account: "Liabilities:Credit Cards:Visa",
        contains_header: 1,
        ignore_column: [4],
        date_format: '%m/%d/%Y',
        output_file: output
      )
      app.walk_backwards

      expect(output.string).to include('Expenses:Automotive:Car Wash')
    end
  end

  context "Issue #64 - regression test" do
    it 'should work for simple file' do
      rows = []
      app =  Reckon::App.new(file: fixture_path('test_money_column.csv'))
      expect { app.each_row_backwards { |n| rows << n } }
        .to output(/Skipping row: 'Date, Note, Amount'/).to_stderr_from_any_process
      expect(rows.length).to eq(2)
      expect(rows[0][:pretty_date]).to eq('2012-03-22')
      expect(rows[0][:pretty_money]).to eq(' $50.00')
      expect(rows[1][:pretty_date]).to eq('2012-03-23')
      expect(rows[1][:pretty_money]).to eq('-$10.00')
    end
  end

  context 'Issue #51 - regression test' do
    it 'should assign correct accounts with tokens' do
      output = StringIO.new
      Reckon::App.new(
        file: fixture_path('51-sample.csv'),
        unattended: true,
        account_tokens_file: fixture_path('51-tokens.yml'),
        ignore_columns: [5],
        bank_account: 'Assets:Chequing',
        output_file: output
      ).walk_backwards
      expect(output.string).not_to include('Income:Unknown')
      expect(output.string.scan('Expenses:Dining:Resturant').size).to eq(8)
    end
  end

  #DATA
  BANK_CSV = (<<-CSV).strip
    DEBIT,20091224120000[0:GMT],"HOST 037196321563 MO        12/22SLICEHOST",-85.00
    CHECK,20091224120000[0:GMT],"Book Store",-20.00
    DEBIT,20091224120000[0:GMT],"GITHUB 041287430274 CA           12/22GITHUB 04",-7.00
    CREDIT,20091223120000[0:GMT],"Some Company vendorpymt                 PPD ID: 59728JSL20",3520.00
    CREDIT,20091223120000[0:GMT],"Blarg BLARG REVENUE                  PPD ID: 00jah78563",1558.52
    DEBIT,20091221120000[0:GMT],"WEBSITE-BALANCE-17DEC09 12        12/17WEBSITE-BAL",-12.23
    DEBIT,20091214120000[0:GMT],"WEBSITE-BALANCE-10DEC09 12        12/10WEBSITE-BAL",-20.96
    CREDIT,20091211120000[0:GMT],"PAYPAL           TRANSFER                   PPD ID: PAYPALSDSL",116.22
    CREDIT,20091210120000[0:GMT],"Some Company vendorpymt                 PPD ID: 5KL3832735",2105.00
  CSV

  BANK_LEDGER = (<<-LEDGER).strip
2004/05/14 * Pay day
  Assets:Bank:Checking          $500.00
  Income:Salary

2004/05/27 Book Store
  Expenses:Books                 $20.00
  Liabilities:MasterCard
LEDGER
end
