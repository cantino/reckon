#!/usr/bin/env ruby
# encoding: utf-8

require "spec_helper"
require 'rubygems'
require 'reckon'

Reckon::CSVParser.settings[:testing] = true

describe Reckon::CSVParser do
  before do
    @chase = Reckon::CSVParser.new(:string => CHASE_CSV)
    @some_other_bank = Reckon::CSVParser.new(:string => SOME_OTHER_CSV)
    @two_money_columns = Reckon::CSVParser.new(:string => TWO_MONEY_COLUMNS_BANK)
    @suntrust_csv = Reckon::CSVParser.new(:string => SUNTRUST_CSV)
    @simple_csv = Reckon::CSVParser.new(:string => SIMPLE_CSV)
    @nationwide = Reckon::CSVParser.new( :string => NATIONWIDE_CSV, :csv_separator => ',', :suffixed => true, :currency => "POUND" )
    @german_date = Reckon::CSVParser.new(:string => GERMAN_DATE_EXAMPLE)
    @danish_kroner_nordea = Reckon::CSVParser.new(:string => DANISH_KRONER_NORDEA_EXAMPLE, :csv_separator => ';', :comma_separates_cents => true)
    @yyyymmdd_date = Reckon::CSVParser.new(:string => YYYYMMDD_DATE_EXAMPLE)
    @spanish_date = Reckon::CSVParser.new(:string => SPANISH_DATE_EXAMPLE, :date_format => '%d/%m/%Y')
    @english_date = Reckon::CSVParser.new(:string => ENGLISH_DATE_EXAMPLE)
    @ing_csv = Reckon::CSVParser.new(:string => ING_CSV, :comma_separates_cents => true )
    @austrian_csv = Reckon::CSVParser.new(:string => AUSTRIAN_EXAMPLE, :comma_separates_cents => true, :csv_separator => ';' )
    @french_csv = Reckon::CSVParser.new(:string => FRENCH_EXAMPLE, :csv_separator => ';', :comma_separates_cents => true)
    @broker_canada = Reckon::CSVParser.new(:string => BROKER_CANADA_EXAMPLE)
    @intuit_mint = Reckon::CSVParser.new(:string => INTUIT_MINT_EXAMPLE)
  end

  it "should be in testing mode" do
    @chase.settings[:testing].should be true
    Reckon::CSVParser.settings[:testing].should be true
  end

  describe "parse" do
    it "should use binary encoding if none specified and chardet fails" do
      allow(CharDet).to receive(:detect).and_return({'encoding' => nil})
      app = Reckon::CSVParser.new(:file => File.expand_path(File.join(File.dirname(__FILE__), "..", "data_fixtures", "extratofake.csv")))
      expect(app.try_encoding("foobarbaz")).to eq("BINARY")
    end
    it "should work with foreign character encodings" do
      app = Reckon::CSVParser.new(:file => File.expand_path(File.join(File.dirname(__FILE__), "..", "data_fixtures", "extratofake.csv")))
      app.columns[0][0..2].should == ["Data", "10/31/2012", "11/01/2012"]
      app.columns[2].first.should == "Histórico"
    end

    it "should work with other separators" do
      Reckon::CSVParser.new(:string => "one;two\nthree;four", :csv_separator => ';').columns.should == [['one', 'three'], ['two', 'four']]
    end

    it 'should parse quoted lines' do
      file = %q("30.03.2015";"29.03.2015";"09.04.2015";"BARAUSZAHLUNGSENTGELT";"5266 xxxx xxxx 9454";"";"0";"EUR";"0,00";"EUR";"-3,50";"0")
      Reckon::CSVParser.new(string: file, csv_separator: ';', comma_separates_cents: true).columns.length.should == 12
    end

    it 'should parse csv with BOM' do
      file = File.expand_path(File.join(File.dirname(__FILE__), "..", "data_fixtures", "bom_utf8_file.csv"))
      Reckon::CSVParser.new(file: file).columns.length.should == 41
    end

    describe 'file with invalid csv in header' do
      file = %q(

="0234500012345678";21/11/2015;19/02/2016;36;19/02/2016;1234,37 EUR

Date de l'opération;Libellé;Détail de l'écriture;Montant de l'opération;Devise
19/02/2016;VIR RECU 508160;VIR RECU 1234567834S DE: Francois REF: 123457891234567894561231 PROVENANCE: DE Allemagne ;50,00;EUR
18/02/2016;COTISATION JAZZ;COTISATION JAZZ ;-8,10;EUR
)
      it 'should ignore invalid header lines' do
        Reckon::CSVParser.new(string: file, contains_header: 4)
      end

      it 'should fail' do
        expect { Reckon::CSVParser.new(string: file, contains_header: 1) }.to raise_error(CSV::MalformedCSVError)
      end
    end
  end

  describe "columns" do
    it "should return the csv transposed" do
      @simple_csv.columns.should == [["entry1", "entry4"], ["entry2", "entry5"], ["entry3", "entry6"]]
      @chase.columns.length.should == 4
    end

    it "should be ok with empty lines" do
      lambda {
        Reckon::CSVParser.new(:string => "one,two\nthree,four\n\n\n\n\n").columns.should == [['one', 'three'], ['two', 'four']]
      }.should_not raise_error
    end
  end

  describe "detect_columns" do
    before do
      @harder_date_example_csv = Reckon::CSVParser.new(:string => HARDER_DATE_EXAMPLE)
    end

    it "should detect the money column" do
      @chase.money_column_indices.should == [3]
      @some_other_bank.money_column_indices.should == [3]
      @two_money_columns.money_column_indices.should == [3, 4]
      @suntrust_csv.money_column_indices.should == [3, 4]
      @nationwide.money_column_indices.should == [3, 4]
      @harder_date_example_csv.money_column_indices.should == [1]
      @danish_kroner_nordea.money_column_indices.should == [3]
      @yyyymmdd_date.money_column_indices.should == [3]
      @ing_csv.money_column_indices.should == [6]
      @austrian_csv.money_column_indices.should == [4]
      @french_csv.money_column_indices.should == [4]
      @broker_canada.money_column_indices.should == [8]
      @intuit_mint.money_column_indices.should == [3]
    end

    it "should detect the date column" do
      @chase.date_column_index.should == 1
      @some_other_bank.date_column_index.should == 1
      @two_money_columns.date_column_index.should == 0
      @harder_date_example_csv.date_column_index.should == 0
      @danish_kroner_nordea.date_column_index.should == 0
      @yyyymmdd_date.date_column_index.should == 1
      @french_csv.date_column_index.should == 1
      @broker_canada.date_column_index.should == 0
      @intuit_mint.date_column_index.should == 0
      Reckon::CSVParser.new(:string => '2014-01-13,"22211100000",-10').date_column_index.should == 0
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
      @nationwide.money_for(0).should == 500.00
      @nationwide.money_for(1).should == -20.00
      @danish_kroner_nordea.money_for(0).should == -48.00
      @danish_kroner_nordea.money_for(1).should == -79.00
      @danish_kroner_nordea.money_for(2).should == 497.90
      @danish_kroner_nordea.money_for(3).should == -995.00
      @danish_kroner_nordea.money_for(4).should == -3452.90
      @danish_kroner_nordea.money_for(5).should == -655.00
      @yyyymmdd_date.money_for(0).should == -123.45
      @ing_csv.money_for(0).should == -136.13
      @ing_csv.money_for(1).should == 375.00
      @austrian_csv.money_for(0).should == -18.00
      @austrian_csv.money_for(2).should == 120.00
      @french_csv.money_for(0).should == -10.00
      @french_csv.money_for(1).should == -5.76
      @broker_canada.money_for(0).should == 12.55
      @broker_canada.money_for(1).should == -81.57
      @intuit_mint.money_for(0).should == 0.01
      @intuit_mint.money_for(1).should == -331.63
    end

    it "should handle the comma_separates_cents option correctly" do
      european_csv = Reckon::CSVParser.new(:string => "$2,00;something\n1.025,67;something else", :csv_separator => ';', :comma_separates_cents => true)
      european_csv.money_for(0).should == 2.00
      european_csv.money_for(1).should == 1025.67
    end

    it "should return negated values if the inverse option is passed" do
      inversed_csv = Reckon::CSVParser.new(:string => INVERSED_CREDIT_CARD, :inverse => true)
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
      @nationwide.date_for(1).month.should == 10
      @ing_csv.date_for(1).month.should == Time.parse("2012/11/12").month
      @ing_csv.date_for(1).day.should == Time.parse("2012/11/12").day
      @broker_canada.date_for(5).year.should == 2014
      @broker_canada.date_for(5).month.should == 1
      @broker_canada.date_for(5).day.should == 7
      @intuit_mint.date_for(1).year.should == 2014
      @intuit_mint.date_for(1).month.should == 2
      @intuit_mint.date_for(1).day.should == 3
    end
  end

  describe "description_for" do
    it "should return the combined fields that are not money for date fields" do
      @chase.description_for(1).should == "CHECK; CHECK 2656"
      @chase.description_for(7).should == "CREDIT; PAYPAL TRANSFER PPD ID: PAYPALSDSL"
    end

    it "should not append empty description column" do
      parser = Reckon::CSVParser.new(:string => '01/09/2015,05354 SUBWAY,8.19,,',:date_format => '%d/%m/%Y')
      parser.description_column_indices.should == [1, 4]
      parser.description_for(0).should == '05354 SUBWAY'
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
      euro_bank = Reckon::CSVParser.new(:string => SOME_OTHER_CSV, :currency => "€", :suffixed => false )
      euro_bank.pretty_money_for(1).should == "-€20.00"
      euro_bank.pretty_money_for(4).should == " €1558.52"
      euro_bank.pretty_money_for(7).should == "-€116.22"
      euro_bank.pretty_money_for(5).should == " €0.23"
      euro_bank.pretty_money_for(6).should == "-€0.96"
    end

    it "work with suffixed currencies such as SEK" do
      swedish_bank = Reckon::CSVParser.new(:string => SOME_OTHER_CSV, :currency => 'SEK', :suffixed => true )
      swedish_bank.pretty_money_for(1).should == "-20.00 SEK"
      swedish_bank.pretty_money_for(4).should == " 1558.52 SEK"
      swedish_bank.pretty_money_for(7).should == "-116.22 SEK"
      swedish_bank.pretty_money_for(5).should == " 0.23 SEK"
      swedish_bank.pretty_money_for(6).should == "-0.96 SEK"
    end

    it "should work with merge columns" do
      @nationwide.pretty_money_for(0).should == " 500.00 POUND"
      @nationwide.pretty_money_for(1).should == "-20.00 POUND"
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

  INVERSED_CREDIT_CARD = (<<-CSV).strip
    2013/01/17,2013/01/16,2013011702,DEBIT,2226,"VODAFONE PREPAY VISA M   AUCKLAND      NZL",30.00
    2013/01/18,2013/01/17,2013011801,DEBIT,2226,"WILSON PARKING           AUCKLAND      NZL",4.60
    2013/01/18,2013/01/17,2013011802,DEBIT,2226,"AUCKLAND TRANSPORT       HENDERSON     NZL",2.00
    2013/01/19,2013/01/19,2013011901,CREDIT,2226,"INTERNET PAYMENT RECEIVED                 ",-500.00
    2013/01/26,2013/01/23,2013012601,DEBIT,2226,"ITUNES NZ                CORK          IRL",64.99
    2013/01/26,2013/01/25,2013012602,DEBIT,2226,"VODAFONE FXFLNE BBND R   NEWTON        NZL",90.26
    2013/01/29,2013/01/29,2013012901,CREDIT,2101,"PAYMENT RECEIVED THANK YOU                ",-27.75
    2013/01/30,2013/01/29,2013013001,DEBIT,2226,"AUCKLAND TRANSPORT       HENDERSON     NZL",3.50
    2013/02/05,2013/02/03,2013020501,DEBIT,2226,"Z BEACH RD               AUCKLAND      NZL",129.89
    2013/02/05,2013/02/03,2013020502,DEBIT,2226,"TOURNAMENT KHYBER PASS   AUCKLAND      NZL",8.00
    2013/02/05,2013/02/04,2013020503,DEBIT,2226,"VODAFONE PREPAY VISA M   AUCKLAND      NZL",30.00
    2013/02/08,2013/02/07,2013020801,DEBIT,2226,"AKLD TRANSPORT PARKING   AUCKLAND      NZL",2.50
    2013/02/08,2013/02/07,2013020802,DEBIT,2226,"AUCKLAND TRANSPORT       HENDERSON     NZL",3.50
    2013/02/12,2013/02/11,2013021201,DEBIT,2226,"AKLD TRANSPORT PARKING   AUCKLAND      NZL",1.50
    2013/02/17,2013/02/17,2013021701,CREDIT,2226,"INTERNET PAYMENT RECEIVED                 ",-12.00
    2013/02/17,2013/02/17,2013021702,CREDIT,2226,"INTERNET PAYMENT RECEIVED                 ",-18.00
  CSV

  TWO_MONEY_COLUMNS_BANK = (<<-CSV).strip
    4/1/2008,Check - 0000000122,122,-$76.00,"","$1,750.06"
    3/28/2008,BLARG    R SH 456930,"","",+$327.49,"$1,826.06"
    3/27/2008,Check - 0000000112,112,-$800.00,"","$1,498.57"
    3/26/2008,Check - 0000000251,251,-$88.55,"","$1,298.57"
    3/26/2008,Check - 0000000251,251,"","+$88.55","$1,298.57"
  CSV

  SUNTRUST_CSV = (<<-CSV).strip
    11/01/2014,0, Deposit,0,500.00,500.00
    11/02/2014,101,Check,100.00,0,400.00
    11/03/2014,102,Check,100.00,0,300.00
    11/04/2014,103,Check,100.00,0,200.00
    11/05/2014,104,Check,100.00,0,100.00
    11/06/2014,105,Check,100.00,0,0.00
    11/17/2014,0, Deposit,0,700.00,700.00
  CSV

  NATIONWIDE_CSV = (<<-CSV).strip
    07 Nov 2013,Bank credit,Bank credit,,£500.00,£500.00
    09 Oct 2013,ATM Withdrawal,Withdrawal,£20.00,,£480.00
    09 Dec 2013,Visa,Supermarket,£19.77,,£460.23
    10 Dec 2013,ATM Withdrawal 2,ATM Withdrawal 4,£100.00,,£360.23
  CSV

  ING_CSV = (<<-CSV).strip
    20121115,From1,Acc,T1,IC,Af,"136,13",Incasso,SEPA Incasso, Opm1
    20121112,Names,NL28 INGB 1200 3244 16,21817,GT,Bij,"375,00", Opm2
    20091117,Names,NL28 INGB 1200 3244 16,21817,GT,Af,"257,50", Opm3
  CSV

  HARDER_DATE_EXAMPLE = (<<-CSV).strip
    10-Nov-9,-123.12,,,TRANSFER DEBIT INTERNET TRANSFER,INTERNET TRANSFER MORTGAGE,0.00,
    09-Nov-10,123.12,,,SALARY SALARY,NGHSKS46383BGDJKD  FOO BAR,432.12,
    04-Nov-11,-1234.00,,,TRANSFER DEBIT INTERNET TRANSFER,INTERNET TRANSFER   SAV TO MECU,0.00,
    04-Nov-9,1234.00,,,TRANSFER CREDIT INTERNET TRANSFER,INTERNET TRANSFER,1234.00,
    28-Oct-10,-123.12,,,TRANSFER DEBIT INTERNET TRANSFER,INTERNET TRANSFER SAV TO MORTGAGE,0.00,
  CSV

  GERMAN_DATE_EXAMPLE = (<<-CSV).strip
    24.12.2009,Check - 0000000122,122,-$76.00,"","$1,750.06"
    24.12.2009,BLARG    R SH 456930,"","",+$327.49,"$1,826.06"
    24.12.2009,Check - 0000000112,112,-$800.00,"","$1,498.57"
  CSV

  DANISH_KRONER_NORDEA_EXAMPLE = (<<-CSV).strip
    16-11-2012;Dankort-nota DSB Kobenhavn  15149;16-11-2012;-48,00;26550,33
    26-10-2012;Dankort-nota Ziggy Cafe     19471;26-10-2012;-79,00;26054,54
    22-10-2012;Dankort-nota H&M Hennes & M 10681;23-10-2012;497,90;25433,54
    12-10-2012;Visa kob DKK     995,00            WWW.ASOS.COM   00000               ;12-10-2012;-995,00;27939,54
    12-09-2012;Dankort-nota B.J. TRADING E 14660;12-09-2012;-3452,90;26164,80
    27-08-2012;Dankort-nota MATAS - 20319  18230;27-08-2012;-655,00;21127,45
  CSV

  YYYYMMDD_DATE_EXAMPLE = (<<-CSV).strip
    DEBIT,20121231,"ODESK***BAL-27DEC12 650-12345 CA 12/28",-123.45
  CSV

  SPANISH_DATE_EXAMPLE = (<<-CSV).strip
    02/12/2009,Check - 0000000122,122,-$76.00,"","$1,750.06"
    02/12/2009,BLARG    R SH 456930,"","",+$327.49,"$1,826.06"
    02/12/2009,Check - 0000000112,112,-$800.00,"","$1,498.57"
  CSV

  ENGLISH_DATE_EXAMPLE = (<<-CSV).strip
    24/12/2009,Check - 0000000122,122,-$76.00,"","$1,750.06"
    24/12/2009,BLARG    R SH 456930,"","",+$327.49,"$1,826.06"
    24/12/2009,Check - 0000000112,112,-$800.00,"","$1,498.57"
  CSV

  AUSTRIAN_EXAMPLE = (<<-CSV).strip
    00075757575;Abbuchung Onlinebanking         654321098765 BG/000002462 BICBICBI AT654000000065432109 Thematische Universität Stadt    ;22.01.2014;22.01.2014;-18,00;EUR
    00075757575;333222111333222             222111333222     OG/000002461 BICBICBIXXX AT333000000003332221 Telekom Land AG RECHNUNG       11/13  333222111333222   ;17.01.2014;17.01.2014;-9,05;EUR
    00075757575;Helm                                         BG/000002460 10000 00007878787 Muster Dr.Beispiel-Vorname    ;15.01.2014;15.01.2014;+120,00;EUR
    00075757575;Gutschrift Dauerauftrag                      BG/000002459 BICBICBI AT787000000007878787 Muster Dr.Beispiel-Vorname    ;15.01.2014;15.01.2014;+22,00;EUR
    00075757575;Bezahlung Bankomat                           MC/000002458 0001  K1 06.01.UM 18.11 Bahn 8020 FSA\\Ort\10 10            2002200EUR   ;07.01.2014;06.01.2014;-37,60;EUR
    00075757575;Bezahlung Bankomat             10.33         MC/000002457 0001  K1 02.01.UM 10.33 Abcdef Electronic\\Wie n\1150           0400444   ;03.01.2014;02.01.2014;-46,42;EUR
    00075757575;050055556666000                              OG/000002456 BKAUATWWXXX AT555500000555566665 JKL Telekommm Stadt GmbH JKL Rechnung 555666555   ;03.01.2014;03.01.2014;-17,15;EUR
    00075757575;Abbuchung Einzugsermächtigung                OG/000002455 INTERNATIONALER AUTOMOBIL-,       10000 00006655665    ;02.01.2014;02.01.2014;-17,40;EUR
    00075757575;POLIZZE 1/01/0101010 Fondsge010101010101nsverOG/000002454 BICBICBIXXX AT101000000101010101 VERSICHERUNG NAMEDERV AG POLIZZE 1/01/0101010 Fondsgebundene Lebensversicherung - fällig 01.01.                                   2014 Folg eprämie ;02.01.2014;02.01.2014;-31,71;EUR
    00075757575;POLIZZE 1/01/0101012 Rentenv010101010102- fälOG/000002453 BICBICBIXXX AT101000000101010102 VERSICHERUNG NAMEDERV AG POLIZZE 1/01/0101012 Rentenversicherung - fällig 01.01.20 14 Folgeprämi                                   e  ;02.01.2014;02.01.2014;-32,45;EUR
    00075757575;Anlass                                       VD/000002452 BKAUATWWBRN AT808800080880880880 Dipl.Ing.Dr. Berta Beispiel   ;02.01.2014;02.01.2014;+61,90;EUR
    00075757575;Abbuchung Onlinebanking         000009999999 BG/000002451 BICBICBI AT099000000009999999 Asdfjklöasdf Asdfjklöasdfjklöasdf   ;02.01.2014;02.01.2014;-104,69;EUR
    00075757575;Abbuchung Onlinebanking                      FE/000002450 AT556600055665566556 CD Stadt Efghij Club Dipl.Ing. Max Muster M005566 - Mitgliedsbeitrag 2014  ;02.01.2014;02.01.2014;-39,00;EUR
  CSV

  FRENCH_EXAMPLE = (<<-CSV).strip
    01234567890;22/01/2014;CHEQUE 012345678901234578ABC000  0000 4381974748378178473744441;0000037;-10,00;
  01234567890;22/01/2014;CHEQUE 012345678901937845500TS1  0000 7439816947047874387438445;0000038;-5,76;
  01234567890;22/01/2014;CARTE 012345 CB:*0123456 XX XXXXXX XXX  33BORDEAUX;00X0X0X;-105,90;
  01234567890;22/01/2014;CARTE 012345 CB:*0123456 XXXXXXXXXXX    33SAINT ANDRE D;00X0X0X;-39,99;
  01234567890;22/01/2014;CARTE 012345 CB:*0123456 XXXXXXX XXXXX  33BORDEAUX;10X9X6X;-36,00;
  01234567890;22/01/2014;PRLV XXXXXXXX ABONNEMENT XXXXXXXXXXXXXX.NET N.EMETTEUR: 324411;0XX0XXX;-40,00;
  01234567890;21/01/2014;CARTE 012345 CB:*0123456 XXXXX     XX33433ST ANDRE DE C;0POBUES;-47,12;
  01234567890;21/01/2014;CARTE 012345 CB:*0123456 XXXXXXXXXXXX33433ST ANDRE DE C;0POBUER;-27,02;
  01234567890;21/01/2014;CARTE 012345 CB:*0123456 XXXXXX XXXXXXXX33ST ANDRE 935/;0POBUEQ;-25,65;
  CSV

  BROKER_CANADA_EXAMPLE = (<<-CSV).strip
    2014-02-10,2014-02-10,Interest,ISHARES S&P/TSX CAPPED REIT IN,XRE,179,,,12.55,CAD
    2014-01-16,2014-01-16,Reinvestment,ISHARES GLOBAL AGRICULTURE IND,COW,3,,,-81.57,CAD
    2014-01-16,2014-01-16,Contribution,CONTRIBUTION,,,,,600.00,CAD
    2014-01-16,2014-01-16,Interest,ISHARES GLOBAL AGRICULTURE IND,COW,200,,,87.05,CAD
    2014-01-14,2014-01-14,Reinvestment,BMO NASDAQ 100 EQTY HEDGED TO,ZQQ,2,,,-54.72,CAD
    2014-01-07,2014-01-10,Sell,BMO NASDAQ 100 EQTY HEDGED TO,ZQQ,-300,27.44,CDN,8222.05,CAD
    2014-01-07,2014-01-07,Interest,BMO S&P/TSX EQUAL WEIGHT BKS I,ZEB,250,,,14.00,CAD
    2013-07-02,2013-07-02,Dividend,SELECT SECTOR SPDR FD SHS BEN,XLB,130,,,38.70,USD
    2013-06-27,2013-06-27,Dividend,ICICI BK SPONSORED ADR,IBN,100,,,66.70,USD
    2013-06-19,2013-06-24,Buy,ISHARES S&P/TSX CAPPED REIT IN,XRE,300,15.90,CDN,-4779.95,CAD
    2013-06-17,2013-06-17,Contribution,CONTRIBUTION,,,,,600.00,CAD
    2013-05-22,2013-05-22,Dividend,NATBK,NA,70,,,58.10,CAD
  CSV

  INTUIT_MINT_EXAMPLE = (<<-CSV).strip
"12/10/2014","Dn Ing Inv","[DN]ING             INV/PLA","0.01","credit","Investments","Chequing","",""
"2/03/2014","Ds Lms Msp Condo","[DS]LMS598          MSP/DIV","331.63","debit","Condo Fees","Chequing","",""
"2/10/2014","Ib Granville","[IB]           2601 GRANVILLE","100.00","debit","Uncategorized","Chequing","",""
"2/06/2014","So Pa","[SO]PA    0005191230116379851","140.72","debit","Mortgage & Rent","Chequing","",""
"2/03/2014","Dn Sun Life","[DN]SUN LIFE        MSP/DIV","943.34","credit","Income","Chequing","",""
"1/30/2014","Transfer to CBT (Savings)","[CW] TF 0004#3409-797","500.00","debit","Transfer","Chequing","",""
"1/30/2014","Costco","[PR]COSTCO WHOLESAL","559.96","debit","Business Services","Chequing","",""
  CSV


end
