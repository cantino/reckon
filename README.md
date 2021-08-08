# Reckon

![Build Status](https://github.com/cantino/reckon/workflows/Build%20Status/badge.svg)

Reckon automagically converts CSV files for use with the command-line accounting tool [Ledger](http://www.ledger-cli.org/).  It also helps you to select the correct accounts associated with the CSV data using Bayesian machine learning.

## Installation

Assuming you have Ruby and [Rubygems](http://rubygems.org/pages/download) installed on your system, simply run

    gem install --user reckon

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
    -a, --account NAME               The Ledger Account this file is for
    -v, --[no-]verbose               Run verbosely
    -i, --inverse                    Use the negative of each amount
    -p, --print-table                Print out the parsed CSV in table form
    -o, --output-file FILE           The ledger file to append to
    -l, --learn-from FILE            An existing ledger file to learn accounts from
        --ignore-columns 1,2,5
                                     Columns to ignore, starts from 1
        --money-column 2
                                     Column number of the money column, starts from 1
        --raw-money
                                     Don't format money column (for stocks)
        --date-column 3
                                     Column number of the date column, starts from 1
        --contains-header [N]
                                     Skip N header rows - default 1
        --csv-separator ','
                                     CSV separator (default ',')
        --comma-separates-cents
                                     Use comma to separate cents ($100,50 vs. $100.50)
        --encoding 'UTF-8'
                                     Specify an encoding for the CSV file
    -c, --currency '$'               Currency symbol to use - default $ (ex £, EUR)
        --date-format FORMAT
                                     CSV file date format (see `date` for format)
        --ledger-date-format FORMAT
                                     Ledger date format (see `date` for format)
    -u, --unattended                 Don't ask questions and guess all the accounts automatically. Use with --learn-from or --account-tokens options.
    -t, --account-tokens FILE        YAML file with manually-assigned tokens for each account (see README)
        --table-output-file FILE
        --default-into-account NAME
                                     Default into account
        --default-outof-account NAME
                                     Default 'out of' account
        --fail-on-unknown-account
                                     Fail on unmatched transactions.
        --suffixed
                                     Append currency symbol as a suffix.
    -h, --help                       Show this message
        --version                    Show version

If you find CSV files that it can't parse, send me examples or pull requests!

## Unattended mode

You can run reckon in a non-interactive mode.
To guess the accounts reckon can use an existing ledger file or a token file with keywords.

`reckon --unattended -a Checking -l 2010.dat -f bank.csv -o ledger.dat`

`reckon --unattended -a Checking --account-tokens tokens.yaml -f bank.csv -o ledger.dat`

In unattended mode, you can use STDIN to read your csv data, by specifying `-` as the argument to `-f`.

`csv_file_generator | reckon --unattended -a Checking -l 2010.dat -o ledger.dat -f -`

### Account Tokens

The account tokens file provides a way to teach reckon about what tokens are associated with an account.  As an example, this `tokens.yaml` file:

    Expenses:
      Bank:
        - 'ING Direct Deposit'

Would tokenize to 'ING', 'Direct' and 'Deposit'.  The matcher would then suggest matches to transactions that included those tokens. (ex 'Chase Direct Deposit')

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

Reckon will use `Income:Unknown` or `Expenses:Unknown` if it can't match a transaction to an account.

You can override these names with the `--default_outof_account` and `--default_into_account` options.

### Substring Match

If, in the above example, you'd prefer to match any transaction that contains the string 'ING Direct Deposit' you have to use a regex:

    Expenses:
      Bank:
        - /ING Direct Deposit/

## Contributing

We encourage you to contribute to Reckon! Here is some information to help you.

### Patches/Pull Requests Process

1. Fork the project.
2. Make your feature addition or bug fix.
3. Add tests for it. This is important so I don't break it in a future version unintentionally.
4. Commit, do not mess with rakefile, version, or history.
   - (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
5. Send me a pull request. Bonus points for topic branches.

### Integration Tests

Reckon has integration test located in `spec/integration`.  These are integration and regression tests for reckon.

Run all the tests:

    ./spec/integration/test.sh

Run a single test

    ./spec/integration/test.sh chase/account_tokens_and_regex

#### Add a new integration test

Each test has it's own directory, which you can add any files you want, but the following files are required:

- `test_args` - arguments to add to the reckon command to test against, can specify `--unattended`, `-f input.csv`, etc
- `output.ledger` - the expected ledger file output

If the result of running reckon with `test_args` does not match `output.ledger`, then the test fails.

Most tests will specify `--unattended`, otherwise reckon prompts for keyboard input.

The convention is to use `input.csv` as the input file, and `tokens.yml` as the tokens file, but it is not required.


## Copyright

Copyright (c) 2013 Andrew Cantino (@cantino). See LICENSE for details.

Thanks to @BlackEdder for many contributions!

Currently maintained by @benprew. Thank you!
