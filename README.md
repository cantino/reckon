# Reckon

Reckon automagically converts CSV files for use with the command-line accounting tool [Ledger](https://github.com/jwiegley/ledger/wiki).  It also helps you to select the correct accounts associated with the CSV data using Bayesian machine learning.

## Installation

Assuming you have Ruby and [Rubygems](http://rubygems.org/pages/download) installed on your system, simply run

    (sudo) gem install reckon

## Example Usage

First, login to your bank and export your transaction data as a CSV file.

To see how the CSV parses:
  
    reckon -f bank.csv -p

To convert to ledger format and label everything, do:
  
    reckon -f bank.csv -o output.dat

To have reckon learn from an existing ledger file, provide it with -l:
  
    reckon -f bank.csv -l 2010.dat -o output.dat

Learn more with

    reckon -h

If you find CSV files that it can't parse, send me examples and I'll try to fix it.

## Note on Patches/Pull Requests

* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with rakefile, version, or history.
  (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.

## Copyright

Copyright (c) 2013 Andrew Cantino. See LICENSE for details.
