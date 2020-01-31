# Reckon

[![Build Status](https://travis-ci.org/cantino/reckon.png?branch=master)](https://travis-ci.org/cantino/reckon)

Reckon automagically converts CSV files for use with the command-line accounting tool [Ledger](http://www.ledger-cli.org/).  It also helps you to select the correct accounts associated with the CSV data using Bayesian machine learning.

## Installation

Assuming you have Ruby and [Rubygems](http://rubygems.org/pages/download) installed on your system, simply run

    (sudo) gem install reckon

## Example Usage

First, login to your bank and export your transaction data as a CSV file.

To see how the CSV parses:

    reckon -f bank.csv -p

If your CSV file has a header on the first line, include `--contains-header`.

To convert to ledger format and label everything, do:

    reckon -f bank.csv -o output.dat

To have reckon learn from an existing ledger file, provide it with -l:

    reckon -f bank.csv -l 2010.dat -o output.dat

Learn more:

    > reckon -h

    Usage: Reckon.rb [options]


    -f, --file FILE                  The CSV file to parse
    -a, --account name               The Ledger Account this file is for
    -v, --[no-]verbose               Run verbosely
    -i, --inverse                    Use the negative of each amount
    -p, --print-table                Print out the parsed CSV in table form
    -o, --output-file FILE           The ledger file to append to
    -l, --learn-from FILE            An existing ledger file to learn accounts from
        --ignore-columns 1,2,5
                                     Columns to ignore in the CSV file - the first column is column 1
        --contains-header [N]
                                     The first row of the CSV is a header and should be skipped. Optionally add the number of rows to skip.
        --csv-separator ','
                                     Separator for parsing the CSV - default is comma.
        --comma-separates-cents
                                     Use comma instead of period to deliminate dollars from cents when parsing ($100,50 instead of $100.50)
        --encoding 'UTF-8'
                                     Specify an encoding for the CSV file; not usually needed
    -c, --currency '$'               Currency symbol to use, defaults to $ (£, EUR)
        --date-format '%d/%m/%Y'
                                     Force the date format (see Ruby DateTime strftime)
    -u, --unattended                 Don't ask questions and guess all the accounts automatically. Used with --learn-from or --account-tokens options.
    -t, --account-tokens FILE        YAML file with manually-assigned tokens for each account (see README)
        --default-into-account name
                                     Default into account
        --default-outof-account name
                                     Default 'out of' account
        --suffixed
                                     If --currency should be used as a suffix. Defaults to false.
    -h, --help                       Show this message
        --version                    Show version

If you find CSV files that it can't parse, send me examples or pull requests!

## Unattended mode

You can run reckon in a non-interactive mode.
To guess the accounts reckon can use an existing ledger file or a token file with keywords.

`reckon --unattended -l 2010.dat -f bank.csv -o ledger.dat`

`reckon --unattended --account-tokens tokens.yaml -f bank.csv -o ledger.dat`

Here's an example of `tokens.yaml`:

```
Income:
  Salary:
    - 'LÖN'
    - 'Salary'
Expenses:
  Bank:
    - 'Comission'
    - 'MasterCard'
  Rent:
    - '0011223344' # Landlord bank number
  Hosting:
    - /hosting/i # This regexp will catch descriptions such as WebHosting or filehosting
'[Internal:Transfer]': # Virtual account
  - '4433221100' # Your own account number
```

If reckon can not guess the accounts it will use `Income:Unknown` or `Expenses:Unknown` names.
You can override them with `--default_outof_account` and `--default_into_account` options.

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

Thanks to @BlackEdder for many contributions!
