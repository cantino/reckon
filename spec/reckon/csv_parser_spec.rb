#!/usr/bin/env ruby

require_relative "../spec_helper"
require 'rubygems'
require_relative '../../lib/reckon'

describe Reckon::CSVParser do
  let(:chase) { Reckon::CSVParser.new(file: fixture_path('chase.csv')) }
  let(:some_other_bank) { Reckon::CSVParser.new(file: fixture_path('some_other.csv')) }
  let(:two_money_columns) {
    Reckon::CSVParser.new(file: fixture_path('two_money_columns.csv'))
  }
  let(:suntrust_csv) { Reckon::CSVParser.new(file: fixture_path('suntrust.csv')) }
  let(:simple_csv) { Reckon::CSVParser.new(file: fixture_path('simple.csv')) }
  let(:nationwide) {
    Reckon::CSVParser.new(file: fixture_path('nationwide.csv'), csv_separator: ',',
                          suffixed: true, currency: "POUND")
  }
  let(:german_date) {
    Reckon::CSVParser.new(file: fixture_path('german_date_example.csv'))
  }
  let(:danish_kroner_nordea) {
    Reckon::CSVParser.new(file: fixture_path('danish_kroner_nordea_example.csv'),
                          csv_separator: ';', comma_separates_cents: true)
  }
  let(:yyyymmdd_date) {
    Reckon::CSVParser.new(file: fixture_path('yyyymmdd_date_example.csv'))
  }
  let(:spanish_date) {
    Reckon::CSVParser.new(file: fixture_path('spanish_date_example.csv'),
                          date_format: '%d/%m/%Y')
  }
  let(:english_date) {
    Reckon::CSVParser.new(file: fixture_path('english_date_example.csv'))
  }
  let(:ing_csv) {
    Reckon::CSVParser.new(file: fixture_path('ing.csv'), comma_separates_cents: true)
  }
  let(:austrian_csv) {
    Reckon::CSVParser.new(file: fixture_path('austrian_example.csv'),
                          comma_separates_cents: true, csv_separator: ';')
  }
  let(:french_csv) {
    Reckon::CSVParser.new(file: fixture_path('french_example.csv'), csv_separator: ';',
                          comma_separates_cents: true)
  }
  let(:broker_canada) {
    Reckon::CSVParser.new(file: fixture_path('broker_canada_example.csv'))
  }
  let(:intuit_mint) {
    Reckon::CSVParser.new(file: fixture_path('intuit_mint_example.csv'))
  }

  describe "parse" do
    it "should use binary encoding if none specified and chardet fails" do
      allow(CharDet).to receive(:detect).and_return({ 'encoding' => nil })
      app = Reckon::CSVParser.new(file: fixture_path("extratofake.csv"))
      expect(app.send(:try_encoding, "foobarbaz")).to eq("BINARY")
    end

    it "should work with foreign character encodings" do
      app = Reckon::CSVParser.new(file: fixture_path("extratofake.csv"))
      app.columns[0][0..2].should == ["Data", "10/31/2012", "11/01/2012"]
      app.columns[2].first.should == "Histórico"
    end

    it "should work with other separators" do
      Reckon::CSVParser.new(:string => "one;two\nthree;four",
                            :csv_separator => ';').columns.should == [
                              ['one', 'three'], ['two', 'four']
                            ]
    end

    it 'should parse quoted lines' do
      file = %q("30.03.2015";"29.03.2015";"09.04.2015";"BARAUSZAHLUNGSENTGELT";"5266 xxxx xxxx 9454";"";"0";"EUR";"0,00";"EUR";"-3,50";"0")
      Reckon::CSVParser.new(string: file, csv_separator: ';',
                            comma_separates_cents: true).columns.length.should == 12
    end

    it 'should parse csv with BOM' do
      file = File.expand_path(fixture_path("bom_utf8_file.csv"))
      Reckon::CSVParser.new(file: file).columns.length.should == 41
    end

    it 'should parse multi-line csv fields' do
      file = File.expand_path(fixture_path("multi-line-field.csv"))
      p = Reckon::CSVParser.new(file: file)
      expect(p.columns[0].length).to eq 2
      expected_field = "In case of errors or questions about your\n" +
                       "        electronic transfers:\n" +
                       "        This is a multi-line string\n" +
                       "        "
      expect(p.columns[-1][-1]).to eq expected_field
    end

    describe 'file with invalid csv in header' do
      let(:invalid_file) { fixture_path('invalid_header_example.csv') }

      it 'should ignore invalid header lines' do
        parser = Reckon::CSVParser.new(file: invalid_file, contains_header: 4)
        expect(parser.csv_data).to eq([
                                        ["19/02/2016", "VIR RECU 508160",
                                         "VIR RECU 1234567834S DE: Francois REF: 123457891234567894561231 PROVENANCE: DE Allemagne ", "50,00", "EUR"], ["18/02/2016", "COTISATION JAZZ", "COTISATION JAZZ ", "-8,10", "EUR"]
                                      ])
      end

      it 'should fail' do
        expect { Reckon::CSVParser.new(file: invalid_file, contains_header: 1) }.to(
          raise_error(CSV::MalformedCSVError)
        )
      end
    end
  end

  describe "columns" do
    it "should return the csv transposed" do
      simple_csv.columns.should == [["entry1", "entry4"], ["entry2", "entry5"],
                                    ["entry3", "entry6"]]
      chase.columns.length.should == 4
    end

    it "should be ok with empty lines" do
      lambda {
        Reckon::CSVParser.new(:string => "one,two\nthree,four\n\n\n\n\n").columns.should == [
          ['one', 'three'], ['two', 'four']
        ]
      }.should_not raise_error
    end
  end

  describe "detect_columns" do
    let(:harder_date_example_csv) {
      Reckon::CSVParser.new(file: fixture_path('harder_date_example.csv'))
    }

    it "should detect the money column" do
      chase.money_column_indices.should == [3]
      some_other_bank.money_column_indices.should == [3]
      two_money_columns.money_column_indices.should == [3, 4]
      suntrust_csv.money_column_indices.should == [3, 4]
      nationwide.money_column_indices.should == [3, 4]
      harder_date_example_csv.money_column_indices.should == [1]
      danish_kroner_nordea.money_column_indices.should == [3]
      yyyymmdd_date.money_column_indices.should == [3]
      ing_csv.money_column_indices.should == [6]
      austrian_csv.money_column_indices.should == [4]
      french_csv.money_column_indices.should == [4]
      broker_canada.money_column_indices.should == [8]
      intuit_mint.money_column_indices.should == [3]
    end

    it "should detect the date column" do
      chase.date_column_index.should == 1
      some_other_bank.date_column_index.should == 1
      two_money_columns.date_column_index.should == 0
      harder_date_example_csv.date_column_index.should == 0
      danish_kroner_nordea.date_column_index.should == 0
      yyyymmdd_date.date_column_index.should == 1
      french_csv.date_column_index.should == 1
      broker_canada.date_column_index.should == 0
      intuit_mint.date_column_index.should == 0
      Reckon::CSVParser.new(:string => '2014-01-13,"22211100000",-10').date_column_index.should == 0
    end

    it "should consider all other columns to be description columns" do
      chase.description_column_indices.should == [0, 2]
      some_other_bank.description_column_indices.should == [0, 2]
      two_money_columns.description_column_indices.should == [1, 2, 5]
      harder_date_example_csv.description_column_indices.should == [2, 3, 4, 5, 6, 7]
      danish_kroner_nordea.description_column_indices.should == [1, 2, 4]
      yyyymmdd_date.description_column_indices.should == [0, 2]
    end
  end

  describe "money_column_indicies" do
    it "should prefer the option over the heuristic" do
      chase = Reckon::CSVParser.new(file: fixture_path('chase.csv'))
      expect(chase.money_column_indices).to eq([3])

      chase = Reckon::CSVParser.new(file: fixture_path('chase.csv'), money_column: 2)
      expect(chase.money_column_indices).to eq([1])
    end
  end

  describe "money_for" do
    it "should return the appropriate fields" do
      chase.money_for(1).should == -20
      chase.money_for(4).should == 1558.52
      chase.money_for(7).should == -116.22
      some_other_bank.money_for(1).should == -20
      some_other_bank.money_for(4).should == 1558.52
      some_other_bank.money_for(7).should == -116.22
      two_money_columns.money_for(0).should == -76
      two_money_columns.money_for(1).should == 327.49
      two_money_columns.money_for(2).should == -800
      two_money_columns.money_for(3).should == -88.55
      two_money_columns.money_for(4).should == 88.55
      nationwide.money_for(0).should == 500.00
      nationwide.money_for(1).should == -20.00
      danish_kroner_nordea.money_for(0).should == -48.00
      danish_kroner_nordea.money_for(1).should == -79.00
      danish_kroner_nordea.money_for(2).should == 497.90
      danish_kroner_nordea.money_for(3).should == -995.00
      danish_kroner_nordea.money_for(4).should == -3452.90
      danish_kroner_nordea.money_for(5).should == -655.00
      yyyymmdd_date.money_for(0).should == -123.45
      ing_csv.money_for(0).should == -136.13
      ing_csv.money_for(1).should == 375.00
      austrian_csv.money_for(0).should == -18.00
      austrian_csv.money_for(2).should == 120.00
      french_csv.money_for(0).should == -10.00
      french_csv.money_for(1).should == -5.76
      broker_canada.money_for(0).should == 12.55
      broker_canada.money_for(1).should == -81.57
      intuit_mint.money_for(0).should == 0.01
      intuit_mint.money_for(1).should == -331.63
    end

    it "should handle the comma_separates_cents option correctly" do
      european_csv = Reckon::CSVParser.new(
        :string => "$2,00;something\n1.025,67;something else", :csv_separator => ';', :comma_separates_cents => true
      )
      european_csv.money_for(0).should == 2.00
      european_csv.money_for(1).should == 1025.67
    end

    it "should return negated values if the inverse option is passed" do
      inversed_csv = Reckon::CSVParser.new(
        file: fixture_path('inversed_credit_card.csv'), inverse: true
      )
      inversed_csv.money_for(0).should == -30.00
      inversed_csv.money_for(3).should == 500.00
    end
  end

  describe "date_column_index" do
    it "should prefer the option over the heuristic" do
      chase = Reckon::CSVParser.new(file: fixture_path('chase.csv'))
      expect(chase.date_column_index).to eq(1)

      chase = Reckon::CSVParser.new(file: fixture_path('chase.csv'), date_column: 3)
      expect(chase.date_column_index).to eq(2)
    end
  end

  describe "date_for" do
    it "should return a parsed date object" do
      chase.date_for(1).year.should == Time.parse("2009/12/24").year
      chase.date_for(1).month.should == Time.parse("2009/12/24").month
      chase.date_for(1).day.should == Time.parse("2009/12/24").day
      some_other_bank.date_for(1).year.should == Time.parse("2010/12/24").year
      some_other_bank.date_for(1).month.should == Time.parse("2010/12/24").month
      some_other_bank.date_for(1).day.should == Time.parse("2010/12/24").day
      german_date.date_for(1).year.should == Time.parse("2009/12/24").year
      german_date.date_for(1).month.should == Time.parse("2009/12/24").month
      german_date.date_for(1).day.should == Time.parse("2009/12/24").day
      danish_kroner_nordea.date_for(0).year.should == Time.parse("2012/11/16").year
      danish_kroner_nordea.date_for(0).month.should == Time.parse("2012/11/16").month
      danish_kroner_nordea.date_for(0).day.should == Time.parse("2012/11/16").day
      yyyymmdd_date.date_for(0).year.should == Time.parse("2012/12/31").year
      yyyymmdd_date.date_for(0).month.should == Time.parse("2012/12/31").month
      yyyymmdd_date.date_for(0).day.should == Time.parse("2012/12/31").day
      spanish_date.date_for(1).year.should == Time.parse("2009/12/02").year
      spanish_date.date_for(1).month.should == Time.parse("2009/12/02").month
      spanish_date.date_for(1).day.should == Time.parse("2009/12/02").day
      english_date.date_for(1).year.should == Time.parse("2009/12/24").year
      english_date.date_for(1).month.should == Time.parse("2009/12/24").month
      english_date.date_for(1).day.should == Time.parse("2009/12/24").day
      nationwide.date_for(1).month.should == 10
      ing_csv.date_for(1).month.should == Time.parse("2012/11/12").month
      ing_csv.date_for(1).day.should == Time.parse("2012/11/12").day
      broker_canada.date_for(5).year.should == 2014
      broker_canada.date_for(5).month.should == 1
      broker_canada.date_for(5).day.should == 7
      intuit_mint.date_for(1).year.should == 2014
      intuit_mint.date_for(1).month.should == 2
      intuit_mint.date_for(1).day.should == 3
    end
  end

  describe "description_for" do
    it "should return the combined fields that are not money for date fields" do
      chase.description_for(1).should == "CHECK; CHECK 2656"
      chase.description_for(7).should == "CREDIT; PAYPAL TRANSFER PPD ID: PAYPALSDSL"
    end

    it "should not append empty description column" do
      parser = Reckon::CSVParser.new(:string => '01/09/2015,05354 SUBWAY,8.19,,',
                                     :date_format => '%d/%m/%Y')
      parser.description_for(0).should == '05354 SUBWAY'
    end

    it "should handle nil description" do
      parser = Reckon::CSVParser.new(string: '2015-09-01,test,3.99')
      expect(parser.description_for(1)).to eq("")
    end
  end

  describe "pretty_money_for" do
    it "work with negative and positive numbers" do
      some_other_bank.pretty_money_for(1).should == "-$20.00"
      some_other_bank.pretty_money_for(4).should == " $1,558.52"
      some_other_bank.pretty_money_for(7).should == "-$116.22"
      some_other_bank.pretty_money_for(5).should == " $0.23"
      some_other_bank.pretty_money_for(6).should == "-$0.96"
    end

    it "work with other currencies such as €" do
      euro_bank = Reckon::CSVParser.new(file: fixture_path('some_other.csv'),
                                        currency: "€", suffixed: false)
      euro_bank.pretty_money_for(1).should == "-€20.00"
      euro_bank.pretty_money_for(4).should == " €1,558.52"
      euro_bank.pretty_money_for(7).should == "-€116.22"
      euro_bank.pretty_money_for(5).should == " €0.23"
      euro_bank.pretty_money_for(6).should == "-€0.96"
    end

    it "work with suffixed currencies such as SEK" do
      swedish_bank = Reckon::CSVParser.new(file: fixture_path('some_other.csv'),
                                           currency: 'SEK', suffixed: true)
      swedish_bank.pretty_money_for(1).should == "-20.00 SEK"
      swedish_bank.pretty_money_for(4).should == " 1,558.52 SEK"
      swedish_bank.pretty_money_for(7).should == "-116.22 SEK"
      swedish_bank.pretty_money_for(5).should == " 0.23 SEK"
      swedish_bank.pretty_money_for(6).should == "-0.96 SEK"
    end

    it "should work with merge columns" do
      nationwide.pretty_money_for(0).should == " 500.00 POUND"
      nationwide.pretty_money_for(1).should == "-20.00 POUND"
    end
  end

  describe '85 regression test' do
    it 'should detect correct date column' do
      p = Reckon::CSVParser.new(file: fixture_path('85-date-example.csv'))
      expect(p.date_column_index).to eq(2)
    end
  end
end
