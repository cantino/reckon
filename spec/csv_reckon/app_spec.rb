#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../spec_helper'
require 'rubygems'
require 'csv_reckon'

describe CSVReckon::App do
  before do
    @chase = CSVReckon::App.new(:string => CHASE_CSV)
    @some_other_bank = CSVReckon::App.new(:string => SOME_OTHER_CSV)
    @two_money_columns = CSVReckon::App.new(:string => TWO_MONEY_COLUMNS_BANK)
    @simple_csv = CSVReckon::App.new(:string => SIMPLE_CSV)
  end

  describe "columns" do
    it "should return the csv transposed" do
      @simple_csv.columns.should == [["entry1", "entry4"], ["entry2", "entry5"], ["entry3", "entry6"]]
      @chase.columns.length.should == 4
    end
  end

  describe "detect_columns" do
    it "should detect the money column" do
      @chase.money_column_indices.should == [3]
      @some_other_bank.money_column_indices.should == [3]
      @two_money_columns.money_column_indices.should == [3, 4]
    end

    it "should detect the date column" do
      @chase.date_column_index.should == 1
      @some_other_bank.date_column_index.should == 1
      @two_money_columns.date_column_index.should == 0
    end

    it "should consider all other columns to be description columns" do
      @chase.description_column_indices.should == [0, 2]
      @some_other_bank.description_column_indices.should == [0, 2]
      @two_money_columns.description_column_indices.should == [1, 2, 5]
    end
  end

  describe "each_index_backwards" do
    it "should hit every index" do
      count = 0
      @chase.each_row_backwards { count += 1}
      count.should == 9
    end
  end

  describe "money_for" do
    it "should return the appropriate fields" do
      @chase.money_for(1).should == -20
      @chase.money_for(4).should == 1558.52
      @chase.money_for(7).should == -116.22
      @some_other_bank.money_for(1).should == -20
      @some_other_bank.money_for(4).should == 1558.52
      @some_other_bank.money_for(7).should == -116.22
      @two_money_columns.money_for(0).should == -76
      @two_money_columns.money_for(1).should == 327.49
      @two_money_columns.money_for(2).should == -800
      @two_money_columns.money_for(3).should == -88.55
      @two_money_columns.money_for(4).should == 88.55
    end
  end

  describe "date_for" do
    it "should return a parsed date object" do
      @chase.date_for(1).should == Time.parse("2009/12/24")
      @some_other_bank.date_for(1).should == Time.parse("2010/12/24")
    end
  end

  describe "description_for" do
    it "should return the combined fields that are not money for date fields" do
      @chase.description_for(1).should == "CHECK; CHECK 2656"
      @chase.description_for(7).should == "CREDIT; PAYPAL TRANSFER PPD ID: PAYPALSDSL"
    end
  end

  describe "pretty_money_for" do
    it "work with negative and positive numbers" do
      @some_other_bank.pretty_money_for(1).should == "-$20.00"
      @some_other_bank.pretty_money_for(4).should == " $1558.52"
      @some_other_bank.pretty_money_for(7).should == "-$116.22"
      @some_other_bank.pretty_money_for(5).should == " $0.23"
      @some_other_bank.pretty_money_for(6).should == "-$0.96"
    end
  end

  describe "merge_columns" do
    it "should work on adjacent columns" do
      @simple_csv.merge_columns(0,1).should == [["entry1 entry2", "entry4 entry5"], ["entry3", "entry6"]]
    end

    it "should work on non-adjacent columns" do
      @simple_csv.merge_columns(0,2).should == [["entry1 entry3", "entry4 entry6"], ["entry2", "entry5"]]
    end
  end



  # Data

  SIMPLE_CSV = "entry1,entry2,entry3\nentry4,entry5,entry6"

  CHASE_CSV = (<<-CSV).strip
    DEBIT,20091224120000[0:GMT],"HOST 037196321563 MO        12/22SLICEHOST",-85.00
    CHECK,20091224120000[0:GMT],"CHECK 2656",-20.00
    DEBIT,20091224120000[0:GMT],"GITHUB 041287430274 CA           12/22GITHUB 04",-7.00
    CREDIT,20091223120000[0:GMT],"Some Company vendorpymt                 PPD ID: 59728JSL20",3520.00
    CREDIT,20091223120000[0:GMT],"Blarg BLARG REVENUE                  PPD ID: 00jah78563",1558.52
    DEBIT,20091221120000[0:GMT],"WEBSITE-BALANCE-17DEC09 12        12/17WEBSITE-BAL",-12.23
    DEBIT,20091214120000[0:GMT],"WEBSITE-BALANCE-10DEC09 12        12/10WEBSITE-BAL",-20.96
    CREDIT,20091211120000[0:GMT],"PAYPAL           TRANSFER                   PPD ID: PAYPALSDSL",-116.22
    CREDIT,20091210120000[0:GMT],"Some Company vendorpymt                 PPD ID: 5KL3832735",2105.00
  CSV

  SOME_OTHER_CSV = (<<-CSV).strip
    DEBIT,2011/12/24,"HOST 037196321563 MO        12/22SLICEHOST",($85.00)
    CHECK,2010/12/24,"CHECK 2656",($20.00)
    DEBIT,2009/12/24,"GITHUB 041287430274 CA           12/22GITHUB 04",($7.00)
    CREDIT,2008/12/24,"Some Company vendorpymt                 PPD ID: 59728JSL20",$3520.00
    CREDIT,2007/12/24,"Blarg BLARG REVENUE                  PPD ID: 00jah78563",$1558.52
    DEBIT,2006/12/24,"WEBSITE-BALANCE-17DEC09 12        12/17WEBSITE-BAL",$.23
    DEBIT,2005/12/24,"WEBSITE-BALANCE-10DEC09 12        12/10WEBSITE-BAL",($0.96)
    CREDIT,2004/12/24,"PAYPAL           TRANSFER                   PPD ID: PAYPALSDSL",($116.22)
    CREDIT,2003/12/24,"Some Company vendorpymt                 PPD ID: 5KL3832735",$2105.00
  CSV

  TWO_MONEY_COLUMNS_BANK = (<<-CSV).strip
    4/1/2008,Check - 0000000122,122,-$76.00,"","$1,750.06"
    3/28/2008,BLARG    R SH 456930,"","",+$327.49,"$1,826.06"
    3/27/2008,Check - 0000000112,112,-$800.00,"","$1,498.57"
    3/26/2008,Check - 0000000251,251,-$88.55,"","$1,298.57"
    3/26/2008,Check - 0000000251,251,"","+$88.55","$1,298.57"
  CSV

end
