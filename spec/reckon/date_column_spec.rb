#!/usr/bin/env ruby
# encoding: utf-8

require "spec_helper"
require 'rubygems'
require 'reckon'

describe Reckon::DateColumn do
  describe "initialize" do
    it "should detect us and world time" do
      Reckon::DateColumn.new( ["01/02/2013", "01/14/2013"] ).endian_precedence.should == [:middle]
      Reckon::DateColumn.new( ["01/02/2013", "14/01/2013"] ).endian_precedence.should == [:little]
    end
    it "should set endian_precedence to default when date format cannot be misinterpreted" do
      Reckon::DateColumn.new( ["2013/01/02"] ).endian_precedence.should == [:middle,:little]
    end
    it "should raise an error when in doubt" do
      expect{ Reckon::DateColumn.new( ["01/02/2013", "01/03/2013"] )}.to raise_error( StandardError )
    end
  end
  describe "for" do
    it "should detect the date" do
      expect(Reckon::DateColumn.new(%w[13/12/2013]).for(0))
        .to eq(Date.new(2013, 12, 13))
      expect(Reckon::DateColumn.new(%w[01/14/2013]).for(0))
        .to eq(Date.new(2013, 1, 14))
      expect(Reckon::DateColumn.new(%w[13/12/2013 21/11/2013]).for(1))
        .to eq(Date.new(2013, 11, 21))
      expect(Reckon::DateColumn.new( ["2013-11-21"] ).for( 0 ))
        .to eq(Date.new(2013, 11, 21))

    end

    it "should correctly use endian_precedence" do
      expect(Reckon::DateColumn.new(%w[01/02/2013 01/14/2013]).for(0))
        .to eq(Date.new(2013, 1, 2))
      expect(Reckon::DateColumn.new(%w[01/02/2013 14/01/2013]).for(0))
        .to eq(Date.new(2013, 2, 1))
    end
  end

  describe "#pretty_for" do
    it 'should use ledger_date_format' do
      expect(Reckon::DateColumn.new(%w[13/02/2013], {ledger_date_format: '%d/%m/%Y'}).pretty_for(0))
               .to eq('13/02/2013')
    end

    it 'should default to is' do
      expect(Reckon::DateColumn.new(%w[13/12/2013]).pretty_for(0))
        .to eq('2013-12-13')
    end
  end
end
