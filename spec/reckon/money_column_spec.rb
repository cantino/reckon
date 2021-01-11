#!/usr/bin/env ruby
# encoding: utf-8

require "spec_helper"
require 'rubygems'
require 'reckon'

describe Reckon::MoneyColumn do
  describe "initialize" do
    it "should convert strings into Money" do
      Reckon::MoneyColumn.new( ["1.00", "-2.00"] ).should == [
        Reckon::Money.new( 1.00 ), Reckon::Money.new( -2.00 ) ]
    end
    it "should convert empty string into nil" do
      Reckon::MoneyColumn.new( ["1.00", ""] ).should == [
        Reckon::Money.new( 1.00 ), nil ]
      Reckon::MoneyColumn.new( ["", "-2.00"] ).should == [
        nil, Reckon::Money.new( -2.00 ) ]
    end
  end

  describe "positive?" do
    it "should return false if one entry negative" do
      Reckon::MoneyColumn.new( ["1.00", "-2.00"] ).positive?.should == false
    end

    it "should return true if all elements positive or nil" do
      Reckon::MoneyColumn.new( ["1.00", "2.00"] ).positive?.should == true
      Reckon::MoneyColumn.new( ["1.00", ""] ).positive?.should == true
    end
  end

  describe "merge" do
    it "should merge two columns" do
      m1 = Reckon::MoneyColumn.new(["1.00", ""])
      m2 = Reckon::MoneyColumn.new(["", "-2.00"])
      expect(m1.merge!(m2)).to(
        eq([Reckon::Money.new(1.00), Reckon::Money.new(-2.00)])
      )

      m1 = Reckon::MoneyColumn.new(["1.00", "0"])
      m2 = Reckon::MoneyColumn.new(["0", "-2.00"])
      expect(m1.merge!(m2)).to(
        eq([Reckon::Money.new(1.00), Reckon::Money.new(-2.00)])
      )
    end

    it "should return nil if columns cannot be merged" do
      m1 = Reckon::MoneyColumn.new(["1.00", ""])
      m2 = Reckon::MoneyColumn.new(["1.00", "-2.00"])
      expect(m1.merge!(m2)).to eq([Reckon::Money.new(0), Reckon::Money.new(-2)])

      m1 = Reckon::MoneyColumn.new(["From1", "Names"])
      m2 = Reckon::MoneyColumn.new(["Acc", "NL28 INGB 1200 3244 16,21817"])
      expect(m1.merge!(m2)).to eq([Reckon::Money.new(-1), Reckon::Money.new("NL28 INGB 1200 3244 16,21817")])
    end

    it "should invert first column if both positive" do
      expect(
        Reckon::MoneyColumn.new(["1.00", ""]).merge!(Reckon::MoneyColumn.new( ["", "2.00"]))
      ).to eq([Reckon::Money.new(-1.00), Reckon::Money.new(2.00)])
    end
  end
end
