#!/usr/bin/env ruby
# encoding: utf-8

require "spec_helper"
require 'rubygems'
require 'reckon'

describe Reckon::Money do
  describe "from_s" do
    it "should handle currency indicators" do
      Reckon::Money::from_s( "$2.00" ).should == 2.00
      Reckon::Money::from_s( "-$1025.67" ).should == -1025.67 
      Reckon::Money::from_s( "$-1025.67" ).should == -1025.67 
    end

    it "should handle the comma_separates_cents option correctly" do
      Reckon::Money::from_s( "$2,00", :comma_separates_cents => true ).should == 2.00
      Reckon::Money::from_s( "-$1025,67", :comma_separates_cents => true ).should == -1025.67 
      Reckon::Money::from_s( "$-1025,67", :comma_separates_cents => true ).should == -1025.67 
    end

    it "should return 0 for an empty string" do
      Reckon::Money::from_s( "" ).should == 0
    end

    it "should handle 1000 indicators correctly" do
      Reckon::Money::from_s( "$2.000,00", :comma_separates_cents => true ).should == 2000.00
      Reckon::Money::from_s( "-$1,025.67" ).should == -1025.67 
    end

    it "should keep numbers together" do
      Reckon::Money::from_s( "1A1" ).should == 1
    end

    it "should prefer numbers with precision of two" do
      Reckon::Money::from_s( "1A2.00" ).should == 2
      Reckon::Money::from_s( "2.00A1" ).should == 2
    end

    it "should handle arbitrary prefixes and postfixes" do
      Reckon::Money::from_s( "AB1.00C" ).should == 1
      Reckon::Money::from_s( "AB0C" ).should == 0
      Reckon::Money::from_s( "AB-2.00C" ).should == -2
    end

    it "should return nil if no numbers are found" do
      Reckon::Money::from_s( "BAC" ).should == nil
    end
  end

  describe "pretty" do
    it "work with negative and positive numbers" do
      Reckon::Money.new( -20.00 ).pretty.should == "-$20.00"
      Reckon::Money.new( 1558.52 ).pretty.should == " $1558.52"
    end

    it "work with other currencies such as €" do
      Reckon::Money.new( -20.00, :currency => "€", :suffixed => false ).pretty.should == "-€20.00"
      Reckon::Money.new( 1558.52, :currency => "€", :suffixed => false ).pretty.should == " €1558.52"
    end

    it "work with suffixed currencies such as SEK" do
      Reckon::Money.new( -20.00, :currency => "SEK", :suffixed => true ).pretty.should == "-20.00 SEK"
      Reckon::Money.new( 1558.52, :currency => "SEK", :suffixed => true ).pretty.should == " 1558.52 SEK"
    end
  end

  describe "likelihood" do
    it "should return the likelihood that a string represents money" do
      Reckon::Money::likelihood( "$20.00" ).should == 45
    end
  end

  describe "equality" do
    it "should be comparable to other money" do
      Reckon::Money.new( 2.0 ).should == Reckon::Money.new( 2.0 )
      Reckon::Money.new( 1.0 ).should <= Reckon::Money.new( 2.0 )
      Reckon::Money.new( 3.0 ).should > Reckon::Money.new( 2.0 )
    end
    it "should be comparable to other float" do
      Reckon::Money.new( 2.0 ).should == 2.0
      Reckon::Money.new( 1.0 ).should <= 2.0
      Reckon::Money.new( 3.0 ).should > 2.0
    end
  end
end
