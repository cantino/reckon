#!/usr/bin/env ruby
# frozen_string_literal: true

require "spec_helper"
require "rubygems"
require "reckon"

# datecolumn specs
module Reckon
  describe DateColumn do
    describe "#initialize" do
      it "should detect us and world time" do
        expect(DateColumn.new(%w[01/02/2013 01/14/2013]).endian_precedence)
          .to eq [:middle]
        expect(DateColumn.new(%w[01/02/2013 14/01/2013]).endian_precedence)
          .to eq [:little]
      end
      it "should set endian_precedence to default when date format cannot be misinterpreted" do
        expect(DateColumn.new(["2013/01/02"]).endian_precedence)
          .to eq %i[middle little]
      end
      it "should raise an error when in doubt" do
        expect { DateColumn.new(["01/02/2013", "01/03/2013"]) }
          .to raise_error(StandardError)
      end
    end

    describe "#for" do
      it "should detect the date" do
        expect(DateColumn.new(%w[13/12/2013]).for(0)).to eq(Date.new(2013, 12, 13))
        expect(DateColumn.new(%w[01/14/2013]).for(0)).to eq(Date.new(2013, 1, 14))
        expect(DateColumn.new(%w[13/12/2013 21/11/2013]).for(1))
          .to eq(Date.new(2013, 11, 21))
        expect(DateColumn.new(["2013-11-21"]).for(0)).to eq(Date.new(2013, 11, 21))
      end

      it "should correctly use endian_precedence" do
        expect(DateColumn.new(%w[01/02/2013 01/14/2013]).for(0))
          .to eq(Date.new(2013, 1, 2))
        expect(DateColumn.new(%w[01/02/2013 14/01/2013]).for(0))
          .to eq(Date.new(2013, 2, 1))
      end
    end

    describe "#pretty_for" do
      it "should use ledger_date_format" do
        expect(
          DateColumn.new(["13/02/2013"],
                         { ledger_date_format: "%d/%m/%Y" }).pretty_for(0)
        )
          .to eq("13/02/2013")
      end

      it "should default to is" do
        expect(DateColumn.new(["13/12/2013"]).pretty_for(0))
          .to eq("2013-12-13")
      end
    end

    describe "#likelihood" do
      it "should prefer numbers that looks like dates" do
        expect(DateColumn.likelihood("123456789"))
          .to be < DateColumn.likelihood("20160102")
      end

      # See https://github.com/cantino/reckon/issues/126
      it "Issue #126 - it shouldn't fail on invalid dates" do
        expect(DateColumn.likelihood("303909302970-07-2023")).to be > 0
      end
    end
  end
end
