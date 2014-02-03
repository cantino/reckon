#!/usr/bin/env ruby
# encoding: utf-8

require "spec_helper"
require 'rubygems'
require 'reckon'

describe Reckon::DateColumn do
  describe "initialize" do
    it "should detect date format" do
      Reckon::DateColumn.new( ["13/12/2014"] ).guess.should == "world"
    end
  end
end
 
