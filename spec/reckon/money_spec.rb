#!/usr/bin/env ruby
# encoding: utf-8

require "spec_helper"
require 'rubygems'
require 'reckon'

describe Reckon::Money do
  describe "parse" do
    it "should handle currency indicators" do
      expect(Reckon::Money.new( "$2.00" )).to eq(2.00)
      expect(Reckon::Money.new("-$1025.67")).to eq(-1025.67)
      expect(Reckon::Money.new("$-1025.67")).to eq(-1025.67)
    end

    it "should handle the comma_separates_cents option correctly" do
      expect(Reckon::Money.new("$2,00", comma_separates_cents: true)).to eq(2.00)
      expect(Reckon::Money.new("-$1025,67", comma_separates_cents: true)).to eq(-1025.67)
      expect(Reckon::Money.new("$-1025,67", comma_separates_cents: true)).to eq(-1025.67)
    end

    it "should return 0 for an empty string" do
      expect(Reckon::Money.new("")).to eq(0)
    end

    it "should handle 1000 indicators correctly" do
      expect(Reckon::Money.new("$2.000,00", comma_separates_cents: true)).to eq(2000.00)
      expect(Reckon::Money.new("-$1,025.67")).to eq(-1025.67)
    end
  end

  describe "pretty" do
    it "work with negative and positive numbers" do
      expect(Reckon::Money.new(-20.00).pretty).to eq("-$20.00")
      expect(Reckon::Money.new(1558.52).pretty).to eq(" $1,558.52")
    end

    it "work with other currencies such as €" do
      expect(Reckon::Money.new(-20.00, currency: "€", suffixed: false).pretty).to eq("-€20.00")
      expect(Reckon::Money.new(1558.52, currency: "€", suffixed: false).pretty).to eq(" €1,558.52")
    end

    it "work with suffixed currencies such as SEK" do
      expect(Reckon::Money.new(-20.00, currency: "SEK", suffixed: true).pretty).to eq("-20.00 SEK")
      expect(Reckon::Money.new(1558.52, currency: "SEK", suffixed: true).pretty).to eq(" 1,558.52 SEK")
    end
  end

  describe "likelihood" do
    it "should return the likelihood that a string represents money" do
      expect(Reckon::Money::likelihood("$20.00")).to eq(65)
    end

    it "should return neutral for empty string" do
      expect(Reckon::Money::likelihood("")).to eq(0)
    end

    it "should recognize non-us currencies" do
      expect(Reckon::Money::likelihood("£480.00")).to eq(30)
      expect(Reckon::Money::likelihood("£1.480,00")).to eq(30)
    end

    it 'should not identify date columns as money' do
      expect(Reckon::Money::likelihood("22.01.2014")).to eq(0)
    end
  end

  describe "equality" do
    it "should be comparable to other money" do
      expect(Reckon::Money.new(2.0)).to eq(Reckon::Money.new(2.0))
      expect(Reckon::Money.new(1.0)).to be <= Reckon::Money.new(2.0)
      expect(Reckon::Money.new(3.0)).to be > Reckon::Money.new(2.0)
    end
    it "should be comparable to other float" do
      expect(Reckon::Money.new(2.0)).to eq(2.0)
      expect(Reckon::Money.new(1.0)).to be <= 2.0
      expect(Reckon::Money.new(3.0)).to be > 2.0
    end
  end
end
