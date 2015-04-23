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
      Reckon::DateColumn.new( ["13/12/2013"] ).for( 0 ).should ==
        Time.new( 2013, 12, 13, 12 )
      Reckon::DateColumn.new( ["01/14/2013"] ).for( 0 ).should ==
        Time.new( 2013, 01, 14, 12 )
      Reckon::DateColumn.new( ["13/12/2013", "21/11/2013"] ).for( 1 ).should ==
        Time.new( 2013, 11, 21, 12 )
      Reckon::DateColumn.new( ["2013-11-21"] ).for( 0 ).should ==
        Time.new( 2013, 11, 21, 12 )

    end

    it "should correctly use endian_precedence" do
      Reckon::DateColumn.new( ["01/02/2013", "01/14/2013"] ).for(0).should ==
        Time.new( 2013, 01, 02, 12 )
      Reckon::DateColumn.new( ["01/02/2013", "14/01/2013"] ).for(0).should ==
        Time.new( 2013, 02, 01, 12 )
    end
  end
end

