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

    it "should return nil for an empty string" do
      Reckon::Money::from_s( "" ).should == nil
      Reckon::Money::from_s( "" ).should_not == 0
    end

    it "should handle 1000 indicators correctly" do
      Reckon::Money::from_s( "$2.000,00", :comma_separates_cents => true ).should == 2000.00
      Reckon::Money::from_s( "-$1,025.67" ).should == -1025.67 
    end
  end

  describe "pretty" do
    it "work with negative and positive numbers" do
      Reckon::Money.new( -20.00 ).pretty.should == "-$20.00"
      Reckon::Money.new( 1558.52 ).pretty.should == " $1558.52"
    end

    it "work with other currencies such as €" do
      Reckon::Money.new( -20.00 ).pretty(:currency => "€", :suffixed => false).should == "-€20.00"
      Reckon::Money.new( 1558.52 ).pretty(:currency => "€", :suffixed => false).should == " €1558.52"
    end

    it "work with suffixed currencies such as SEK" do
      Reckon::Money.new( -20.00 ).pretty(:currency => "SEK", :suffixed => true).should == "-20.00 SEK"
      Reckon::Money.new( 1558.52 ).pretty(:currency => "SEK", :suffixed => true).should == " 1558.52 SEK"
    end
  end
  describe "likelihood" do
    it "should return the likelihood that a string represents money" do
      Reckon::Money::likelihood( "$20.00" ).should == 45
    end
  end
end
