# encoding: utf-8

require "./spec/spec_helper"

Reckon::App.settings[:testing] = true

describe Reckon::App do
  before do
    @chase                = Reckon::App.new(:string => Fixtures.data[:chase_csv])
    @some_other_bank      = Reckon::App.new(:string => Fixtures.data[:some_other_csv])
    @two_money_columns    = Reckon::App.new(:string => Fixtures.data[:two_money_columns_bank])
    @simple_csv           = Reckon::App.new(:string => Fixtures.data[:simple_csv])
    @german_date          = Reckon::App.new(:string => Fixtures.data[:german_date_example])
    @danish_kroner_nordea = Reckon::App.new(:string => Fixtures.data[:danish_kroner_nordea_example], :csv_separator => ';', :comma_separates_cents => true)
    @yyyymmdd_date        = Reckon::App.new(:string => Fixtures.data[:yyyymmdd_date_example])
    @spanish_date         = Reckon::App.new(:string => Fixtures.data[:spanish_date_example], :date_format => '%d/%m/%Y')
    @english_date         = Reckon::App.new(:string => Fixtures.data[:english_date_example])

    @german_bank = Reckon::App.new(:string => Fixtures.data[:german_bank_example],
      :csv_separator  => ';',
      :ignore_columns => [1,3]
    )
  end

  it "should be in testing mode" do
    @chase.settings[:testing].should be_true
    Reckon::App.settings[:testing].should be_true
  end

  describe "parse" do
    it "should work with foreign character encodings" do
      app = Reckon::App.new(:file => File.expand_path(File.join(File.dirname(__FILE__), "..", "data_fixtures", "extratofake.csv")))
      app.columns[0][0..2].should == ["Data", "10/31/2012", "11/01/2012"]
      app.columns[2].first.should == "Hist\u00F3rico"
    end

    it "should work with other separators" do
      Reckon::App.new(:string => "one;two\nthree;four", :csv_separator => ';').columns.should == [['one', 'three'], ['two', 'four']]
    end
  end

  describe "columns" do
    it "should return the csv transposed" do
      @simple_csv.columns.should == [["entry1", "entry4"], ["entry2", "entry5"], ["entry3", "entry6"]]
      @chase.columns.length.should == 4
    end

    it "should be ok with empty lines" do
      lambda {
        Reckon::App.new(:string => "one,two\nthree,four\n\n\n\n\n").columns.should == [['one', 'three'], ['two', 'four']]
      }.should_not raise_error
    end
  end

  describe "detect_columns" do
    before do
      @harder_date_example_csv = Reckon::App.new(:string => Fixtures.data[:harder_date_example])
    end

    it "should detect the money column" do
      @chase.money_column_indices.should == [3]
      @some_other_bank.money_column_indices.should == [3]
      @two_money_columns.money_column_indices.should == [3, 4]
      @harder_date_example_csv.money_column_indices.should == [1]
      @danish_kroner_nordea.money_column_indices.should == [3]
      @yyyymmdd_date.money_column_indices.should == [3]
    end

    it "should detect the date column" do
      @chase.date_column_index.should == 1
      @some_other_bank.date_column_index.should == 1
      @two_money_columns.date_column_index.should == 0
      @harder_date_example_csv.date_column_index.should == 0
      @danish_kroner_nordea.date_column_index.should == 0
      @yyyymmdd_date.date_column_index.should == 1
    end

    it "should consider all other columns to be description columns" do
      @chase.description_column_indices.should == [0, 2]
      @some_other_bank.description_column_indices.should == [0, 2]
      @two_money_columns.description_column_indices.should == [1, 2, 5]
      @harder_date_example_csv.description_column_indices.should == [2, 3, 4, 5, 6, 7]
      @danish_kroner_nordea.description_column_indices.should == [1, 2, 4]
      @yyyymmdd_date.description_column_indices.should == [0, 2]
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
      @danish_kroner_nordea.money_for(0).should == -48.00
      @danish_kroner_nordea.money_for(1).should == -79.00
      @danish_kroner_nordea.money_for(2).should == 497.90
      @danish_kroner_nordea.money_for(3).should == -995.00
      @danish_kroner_nordea.money_for(4).should == -3452.90
      @danish_kroner_nordea.money_for(5).should == -655.00
      @yyyymmdd_date.money_for(0).should == -123.45
    end

    it "should handle the comma_separates_cents option correctly" do
      european_csv = Reckon::App.new(:string => "$2,00;something\n1.025,67;something else", :csv_separator => ';', :comma_separates_cents => true)
      european_csv.money_for(0).should == 2.00
      european_csv.money_for(1).should == 1025.67
    end

    it "should return negated values if the inverse option is passed" do

      inversed_csv = Reckon::App.new(:string => Fixtures.data[:inversed_credit_card], :inverse => true)
      inversed_csv.money_for(0).should == -30.00
      inversed_csv.money_for(3).should == 500.00
    end
  end

  describe "date_for" do
    it "should return a parsed date object" do
      @chase.date_for(1).year.should == Time.parse("2009/12/24").year
      @chase.date_for(1).month.should == Time.parse("2009/12/24").month
      @chase.date_for(1).day.should == Time.parse("2009/12/24").day
      @some_other_bank.date_for(1).year.should == Time.parse("2010/12/24").year
      @some_other_bank.date_for(1).month.should == Time.parse("2010/12/24").month
      @some_other_bank.date_for(1).day.should == Time.parse("2010/12/24").day
      @german_date.date_for(1).year.should == Time.parse("2009/12/24").year
      @german_date.date_for(1).month.should == Time.parse("2009/12/24").month
      @german_date.date_for(1).day.should == Time.parse("2009/12/24").day
      @danish_kroner_nordea.date_for(0).year.should == Time.parse("2012/11/16").year
      @danish_kroner_nordea.date_for(0).month.should == Time.parse("2012/11/16").month
      @danish_kroner_nordea.date_for(0).day.should == Time.parse("2012/11/16").day
      @yyyymmdd_date.date_for(0).year.should == Time.parse("2012/12/31").year
      @yyyymmdd_date.date_for(0).month.should == Time.parse("2012/12/31").month
      @yyyymmdd_date.date_for(0).day.should == Time.parse("2012/12/31").day
      @spanish_date.date_for(1).year.should == Time.parse("2009/12/02").year
      @spanish_date.date_for(1).month.should == Time.parse("2009/12/02").month
      @spanish_date.date_for(1).day.should == Time.parse("2009/12/02").day
      @english_date.date_for(1).year.should == Time.parse("2009/12/24").year
      @english_date.date_for(1).month.should == Time.parse("2009/12/24").month
      @english_date.date_for(1).day.should == Time.parse("2009/12/24").day
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

    it "work with other currencies such as €" do

      euro_bank = Reckon::App.new(:string => Fixtures.data[:some_other_csv], :currency => "€", :suffixed => false )
      euro_bank.pretty_money_for(1).should == "-€20.00"
      euro_bank.pretty_money_for(4).should == " €1558.52"
      euro_bank.pretty_money_for(7).should == "-€116.22"
      euro_bank.pretty_money_for(5).should == " €0.23"
      euro_bank.pretty_money_for(6).should == "-€0.96"
    end

    it "work with suffixed currencies such as SEK" do
      swedish_bank = Reckon::App.new(:string => Fixtures.data[:some_other_csv], :currency => 'SEK', :suffixed => true )
      swedish_bank.pretty_money_for(1).should == "-20.00 SEK"
      swedish_bank.pretty_money_for(4).should == " 1558.52 SEK"
      swedish_bank.pretty_money_for(7).should == "-116.22 SEK"
      swedish_bank.pretty_money_for(5).should == " 0.23 SEK"
      swedish_bank.pretty_money_for(6).should == "-0.96 SEK"
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
end
