#!/usr/bin/env ruby
# encoding: utf-8

require "spec_helper"
require 'rubygems'
require 'reckon'

describe Reckon::App do
  before do
    @chase = Reckon::App.new(:string => BANK_CSV)
    @rows = []
    @chase.each_row_backwards { |row| @rows.push( row ) }
  end

  describe "each_row_backwards" do
    it "should return rows with hashes" do
      @rows[0][:pretty_date].should == "2009/12/10"
      @rows[0][:pretty_money].should == " $2105.00"
      @rows[0][:description].should == "CREDIT; Some Company vendorpymt PPD ID: 5KL3832735"
      @rows[1][:pretty_date].should == "2009/12/11"
      @rows[1][:pretty_money].should == "-$116.22"
      @rows[1][:description].should == "CREDIT; PAYPAL TRANSFER PPD ID: PAYPALSDSL"
    end
  end
  
  #DATA
  BANK_CSV = (<<-CSV).strip
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
end
