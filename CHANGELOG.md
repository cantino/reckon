# Changelog

## [v0.8.0](https://github.com/cantino/reckon/tree/v0.8.0) (2021-08-08)

[Full Changelog](https://github.com/cantino/reckon/compare/v0.7.2...v0.8.0)

**Closed issues:**

- --date-format '%d/%m/%Y' not working [\#113](https://github.com/cantino/reckon/issues/113)
- Reckon behaviour does not match what is explained on README.md [\#112](https://github.com/cantino/reckon/issues/112)
- --date-format '%d/%m/%Y' not working [\#111](https://github.com/cantino/reckon/issues/111)
- --date-format '%d/ [\#110](https://github.com/cantino/reckon/issues/110)

**Merged pull requests:**

- Add ledger-date-format option to specify ledger file date format [\#114](https://github.com/cantino/reckon/pull/114) ([benprew](https://github.com/benprew))

## [v0.7.2](https://github.com/cantino/reckon/tree/v0.7.2) (2021-04-22)

[Full Changelog](https://github.com/cantino/reckon/compare/v0.7.1...v0.7.2)

**Closed issues:**

- \[feature request\] Better format for large transactions [\#108](https://github.com/cantino/reckon/issues/108)
- cosine similarity not comparing documents correctly [\#106](https://github.com/cantino/reckon/issues/106)

**Merged pull requests:**

- Add thousands separator in money output.  Fixes \#108. [\#109](https://github.com/cantino/reckon/pull/109) ([benprew](https://github.com/benprew))
- Cosine similarity should use all docs tokens. not just matched tokens. [\#107](https://github.com/cantino/reckon/pull/107) ([benprew](https://github.com/benprew))
- Test getting expect working with actions [\#105](https://github.com/cantino/reckon/pull/105) ([benprew](https://github.com/benprew))

## [v0.7.1](https://github.com/cantino/reckon/tree/v0.7.1) (2021-02-07)

[Full Changelog](https://github.com/cantino/reckon/compare/v0.7.0...v0.7.1)

**Closed issues:**

- bug when asking for account name [\#103](https://github.com/cantino/reckon/issues/103)

## [v0.7.0](https://github.com/cantino/reckon/tree/v0.7.0) (2021-02-06)

[Full Changelog](https://github.com/cantino/reckon/compare/v0.6.2...v0.7.0)

**Closed issues:**

- fail on unknown accounts [\#96](https://github.com/cantino/reckon/issues/96)

**Merged pull requests:**

- Fail on unknown account [\#102](https://github.com/cantino/reckon/pull/102) ([benprew](https://github.com/benprew))
- Joined split sentence to one [\#101](https://github.com/cantino/reckon/pull/101) ([RidaAyed](https://github.com/RidaAyed))

## [v0.6.2](https://github.com/cantino/reckon/tree/v0.6.2) (2021-01-25)

[Full Changelog](https://github.com/cantino/reckon/compare/v0.6.1...v0.6.2)

**Closed issues:**

- spaces in tokens [\#97](https://github.com/cantino/reckon/issues/97)
- read from stdin [\#95](https://github.com/cantino/reckon/issues/95)

**Merged pull requests:**

- Allow using '-' as filename in -f to read csv from STDIN.  Fixes \#95 [\#98](https://github.com/cantino/reckon/pull/98) ([benprew](https://github.com/benprew))

## [v0.6.1](https://github.com/cantino/reckon/tree/v0.6.1) (2021-01-23)

[Full Changelog](https://github.com/cantino/reckon/compare/v0.6.0...v0.6.1)

**Implemented enhancements:**

- \[Feature Request\] Note flag --add-notes in CLI to allow additional notes for each ledger entry [\#86](https://github.com/cantino/reckon/issues/86)

**Closed issues:**

- Migrate CI system from travis-ci.org [\#93](https://github.com/cantino/reckon/issues/93)
- \[Feature Request\] Pipe ledger file input to the bayesian predictor \(instead of csv\) [\#91](https://github.com/cantino/reckon/issues/91)

**Merged pull requests:**

- Add github actions [\#100](https://github.com/cantino/reckon/pull/100) ([benprew](https://github.com/benprew))
- Add documentation for doing a substring match.  Fixes \#97 [\#99](https://github.com/cantino/reckon/pull/99) ([benprew](https://github.com/benprew))
- Test fixes [\#94](https://github.com/cantino/reckon/pull/94) ([benprew](https://github.com/benprew))

## [v0.6.0](https://github.com/cantino/reckon/tree/v0.6.0) (2020-09-04)

[Full Changelog](https://github.com/cantino/reckon/compare/v0.5.4...v0.6.0)

**Fixed bugs:**

- \[BUG\] Reckon appears not to be parsing ISO standard date yyyy-mm-dd? [\#85](https://github.com/cantino/reckon/issues/85)

**Closed issues:**

- duplicate detection [\#16](https://github.com/cantino/reckon/issues/16)

**Merged pull requests:**

- Add ability to add note to transaction when entering it [\#89](https://github.com/cantino/reckon/pull/89) ([benprew](https://github.com/benprew))

## [v0.5.4](https://github.com/cantino/reckon/tree/v0.5.4) (2020-06-05)

[Full Changelog](https://github.com/cantino/reckon/compare/v0.5.3...v0.5.4)

**Fixed bugs:**

- order of transactions [\#88](https://github.com/cantino/reckon/issues/88)
- Is reckon failing to handle comments when learning? [\#87](https://github.com/cantino/reckon/issues/87)

## [v0.5.3](https://github.com/cantino/reckon/tree/v0.5.3) (2020-05-02)

[Full Changelog](https://github.com/cantino/reckon/compare/v0.5.2...v0.5.3)

**Closed issues:**

- \[FEATURE REQUEST\] Ask for currency of Account and output in output file in standard format of xxxx TLA for currency [\#84](https://github.com/cantino/reckon/issues/84)

## [v0.5.2](https://github.com/cantino/reckon/tree/v0.5.2) (2020-03-07)

[Full Changelog](https://github.com/cantino/reckon/compare/v0.5.1...v0.5.2)

**Closed issues:**

- \[Bug\]? Reckon fails to run on ruby 2.7.0 on Catalina  [\#83](https://github.com/cantino/reckon/issues/83)
- --account-tokens issue [\#51](https://github.com/cantino/reckon/issues/51)

## [v0.5.1](https://github.com/cantino/reckon/tree/v0.5.1) (2020-02-25)

[Full Changelog](https://github.com/cantino/reckon/compare/v0.5.0...v0.5.1)

**Closed issues:**

- Error Importing [\#64](https://github.com/cantino/reckon/issues/64)

**Merged pull requests:**

- guard against rows that don't parse dates [\#82](https://github.com/cantino/reckon/pull/82) ([benprew](https://github.com/benprew))

## [v0.5.0](https://github.com/cantino/reckon/tree/v0.5.0) (2020-02-19)

[Full Changelog](https://github.com/cantino/reckon/compare/v0.4.4...v0.5.0)

**Closed issues:**

- g [\#75](https://github.com/cantino/reckon/issues/75)
- Learn-from not working [\#74](https://github.com/cantino/reckon/issues/74)
- Tokens YAML fails to match [\#73](https://github.com/cantino/reckon/issues/73)
- Missing or stray quote in line error [\#71](https://github.com/cantino/reckon/issues/71)
- Support ISO 8601 formatting of dates in ledger file [\#70](https://github.com/cantino/reckon/issues/70)
- Looking for a new maintainer for Reckon [\#68](https://github.com/cantino/reckon/issues/68)
- Reckon undefined method to\_h when trying to parse csv file  [\#66](https://github.com/cantino/reckon/issues/66)
- Runtime error [\#65](https://github.com/cantino/reckon/issues/65)
- Reckon doesn't learn from multiple sources [\#63](https://github.com/cantino/reckon/issues/63)
- problem of importing file [\#59](https://github.com/cantino/reckon/issues/59)
- Problem with file in which every column is quoted. [\#58](https://github.com/cantino/reckon/issues/58)
- Error in reckon for the same format csv file [\#57](https://github.com/cantino/reckon/issues/57)
- Parsing account names does not work if currency symbol is different from $ [\#56](https://github.com/cantino/reckon/issues/56)
- Problem reading csv file [\#55](https://github.com/cantino/reckon/issues/55)
- Problem with mint file [\#53](https://github.com/cantino/reckon/issues/53)
- --money-column [\#43](https://github.com/cantino/reckon/issues/43)

**Merged pull requests:**

- Fix bugs in ledger file parsing.  Fixes \#56. [\#81](https://github.com/cantino/reckon/pull/81) ([benprew](https://github.com/benprew))
- Better file encoding suggestions [\#80](https://github.com/cantino/reckon/pull/80) ([benprew](https://github.com/benprew))
- :bug: fix matching algorithm, add logging and a spec helper.  Fixes \#73 [\#79](https://github.com/cantino/reckon/pull/79) ([benprew](https://github.com/benprew))
- bug: invalid header lines should be ignored, not parsed. [\#78](https://github.com/cantino/reckon/pull/78) ([benprew](https://github.com/benprew))
- convert default date format to iso8601 [\#77](https://github.com/cantino/reckon/pull/77) ([benprew](https://github.com/benprew))
- Fix rspec failure for ruby 2.3 and 2.4 [\#69](https://github.com/cantino/reckon/pull/69) ([BlackEdder](https://github.com/BlackEdder))
- Allow setting of money and date columns by index [\#67](https://github.com/cantino/reckon/pull/67) ([cantino](https://github.com/cantino))

## [v0.4.4](https://github.com/cantino/reckon/tree/v0.4.4) (2015-12-02)

[Full Changelog](https://github.com/cantino/reckon/compare/v0.4.3...v0.4.4)

**Merged pull requests:**

- Regexp support in the tokens file [\#54](https://github.com/cantino/reckon/pull/54) ([vzctl](https://github.com/vzctl))

## [v0.4.3](https://github.com/cantino/reckon/tree/v0.4.3) (2015-08-16)

[Full Changelog](https://github.com/cantino/reckon/compare/v0.4.2...v0.4.3)

## [v0.4.2](https://github.com/cantino/reckon/tree/v0.4.2) (2015-08-08)

[Full Changelog](https://github.com/cantino/reckon/compare/v0.4.1...v0.4.2)

**Merged pull requests:**

- Ignore empty description columns [\#52](https://github.com/cantino/reckon/pull/52) ([vzctl](https://github.com/vzctl))

## [v0.4.1](https://github.com/cantino/reckon/tree/v0.4.1) (2015-07-08)

[Full Changelog](https://github.com/cantino/reckon/compare/v0.4.0...v0.4.1)

**Closed issues:**

- Unattended [\#50](https://github.com/cantino/reckon/issues/50)
- Debit/Credit Columns from SunTrust [\#42](https://github.com/cantino/reckon/issues/42)

**Merged pull requests:**

- \[RFC\] Fix \#42: Work with suntrust double column csv files [\#48](https://github.com/cantino/reckon/pull/48) ([BlackEdder](https://github.com/BlackEdder))

## [v0.4.0](https://github.com/cantino/reckon/tree/v0.4.0) (2015-06-05)

[Full Changelog](https://github.com/cantino/reckon/compare/v0.3.10...v0.4.0)

**Implemented enhancements:**

- Tab completion for transactions [\#40](https://github.com/cantino/reckon/issues/40)
- feature: "unattended" mode [\#3](https://github.com/cantino/reckon/issues/3)

**Closed issues:**

- Missing or stray quote error [\#38](https://github.com/cantino/reckon/issues/38)

**Merged pull requests:**

- Better ISO 8601 dates support [\#49](https://github.com/cantino/reckon/pull/49) ([vzctl](https://github.com/vzctl))
- Unattended mode and custom tokens support [\#47](https://github.com/cantino/reckon/pull/47) ([vzctl](https://github.com/vzctl))
- \[RFC\] Implement issue \#40: Tab completion [\#46](https://github.com/cantino/reckon/pull/46) ([BlackEdder](https://github.com/BlackEdder))
- set readline to allow for backspace in ask dialog [\#44](https://github.com/cantino/reckon/pull/44) ([mrtazz](https://github.com/mrtazz))
- Fix --encoding option [\#41](https://github.com/cantino/reckon/pull/41) ([mamciek](https://github.com/mamciek))

## [v0.3.10](https://github.com/cantino/reckon/tree/v0.3.10) (2014-08-16)

[Full Changelog](https://github.com/cantino/reckon/compare/v0.3.9...v0.3.10)

**Merged pull requests:**

- Bumped version number [\#37](https://github.com/cantino/reckon/pull/37) ([BlackEdder](https://github.com/BlackEdder))

## [v0.3.9](https://github.com/cantino/reckon/tree/v0.3.9) (2014-02-20)

[Full Changelog](https://github.com/cantino/reckon/compare/v0.3.8...v0.3.9)

**Closed issues:**

- Idea/discussion: csv parser [\#25](https://github.com/cantino/reckon/issues/25)
- Silently misinterprets UK dates [\#18](https://github.com/cantino/reckon/issues/18)

**Merged pull requests:**

- Added spec for csv files from Broker Canada [\#36](https://github.com/cantino/reckon/pull/36) ([BlackEdder](https://github.com/BlackEdder))
- Date format [\#35](https://github.com/cantino/reckon/pull/35) ([BlackEdder](https://github.com/BlackEdder))
- Added example from a french bank [\#34](https://github.com/cantino/reckon/pull/34) ([BlackEdder](https://github.com/BlackEdder))
- Austrian example [\#33](https://github.com/cantino/reckon/pull/33) ([BlackEdder](https://github.com/BlackEdder))
- Ing csv [\#30](https://github.com/cantino/reckon/pull/30) ([BlackEdder](https://github.com/BlackEdder))
- Further improvements in nationwide csv handling [\#29](https://github.com/cantino/reckon/pull/29) ([BlackEdder](https://github.com/BlackEdder))
- Refactor: Add money class [\#28](https://github.com/cantino/reckon/pull/28) ([BlackEdder](https://github.com/BlackEdder))
- Initial split of CSVparser from class App [\#27](https://github.com/cantino/reckon/pull/27) ([BlackEdder](https://github.com/BlackEdder))
- Updated version of pull request 24: Allow for other currency symbols while calculating money\_score [\#26](https://github.com/cantino/reckon/pull/26) ([BlackEdder](https://github.com/BlackEdder))
- Change double column detection [\#23](https://github.com/cantino/reckon/pull/23) ([BlackEdder](https://github.com/BlackEdder))
- Added optional argument to contains\_header to skip multiple header lines [\#22](https://github.com/cantino/reckon/pull/22) ([BlackEdder](https://github.com/BlackEdder))
- Add a Bitdeli Badge to README [\#20](https://github.com/cantino/reckon/pull/20) ([bitdeli-chef](https://github.com/bitdeli-chef))
- Update README to show latest usage info [\#19](https://github.com/cantino/reckon/pull/19) ([purcell](https://github.com/purcell))

## [v0.3.8](https://github.com/cantino/reckon/tree/v0.3.8) (2013-07-03)

[Full Changelog](https://github.com/cantino/reckon/compare/v0.3.7...v0.3.8)

**Implemented enhancements:**

- Support other currencies [\#7](https://github.com/cantino/reckon/issues/7)

**Closed issues:**

- Add support for dates in spanish dd/mm/yyyy [\#13](https://github.com/cantino/reckon/issues/13)
- Problems with my csv file [\#8](https://github.com/cantino/reckon/issues/8)

**Merged pull requests:**

- add support for spanish dates dd/mm/yyyy closes \#13 [\#14](https://github.com/cantino/reckon/pull/14) ([mauromorales](https://github.com/mauromorales))
- fix issue showing true when parsing the currency option related to \#7 [\#12](https://github.com/cantino/reckon/pull/12) ([mauromorales](https://github.com/mauromorales))

## [v0.3.7](https://github.com/cantino/reckon/tree/v0.3.7) (2013-06-27)

[Full Changelog](https://github.com/cantino/reckon/compare/v0.3.6...v0.3.7)

**Merged pull requests:**

- Updated the sources to allow for custom curreny [\#11](https://github.com/cantino/reckon/pull/11) ([ghost](https://github.com/ghost))
- Add --account option on the commandline [\#10](https://github.com/cantino/reckon/pull/10) ([copiousfreetime](https://github.com/copiousfreetime))

## [v0.3.6](https://github.com/cantino/reckon/tree/v0.3.6) (2013-04-30)

[Full Changelog](https://github.com/cantino/reckon/compare/v0.3.5...v0.3.6)

**Closed issues:**

- iso-8859-1 CSV with accented chars =\> invalid byte sequence in UTF-8 \(ArgumentError\) [\#5](https://github.com/cantino/reckon/issues/5)
- Ruby 2.0 compatibility [\#4](https://github.com/cantino/reckon/issues/4)

**Merged pull requests:**

- Recognize yyyymmdd date in Reckon::App\#date\_for. [\#9](https://github.com/cantino/reckon/pull/9) ([mhoogendoorn](https://github.com/mhoogendoorn))

## [v0.3.5](https://github.com/cantino/reckon/tree/v0.3.5) (2013-03-24)

[Full Changelog](https://github.com/cantino/reckon/compare/v0.3.4...v0.3.5)

**Closed issues:**

- backtrace trying to run reckon -f [\#2](https://github.com/cantino/reckon/issues/2)

**Merged pull requests:**

- Inverse mode [\#6](https://github.com/cantino/reckon/pull/6) ([nathankot](https://github.com/nathankot))

## [v0.3.4](https://github.com/cantino/reckon/tree/v0.3.4) (2013-02-16)

[Full Changelog](https://github.com/cantino/reckon/compare/v0.3.3...v0.3.4)

**Merged pull requests:**

- adds support for Nordea csv files [\#1](https://github.com/cantino/reckon/pull/1) ([x2q](https://github.com/x2q))

## [v0.3.3](https://github.com/cantino/reckon/tree/v0.3.3) (2013-01-13)

[Full Changelog](https://github.com/cantino/reckon/compare/v0.3.1...v0.3.3)

## [v0.3.1](https://github.com/cantino/reckon/tree/v0.3.1) (2012-07-30)

[Full Changelog](https://github.com/cantino/reckon/compare/v0.3.2...v0.3.1)

## [v0.3.2](https://github.com/cantino/reckon/tree/v0.3.2) (2012-07-30)

[Full Changelog](https://github.com/cantino/reckon/compare/5c07bea3fe63f9b909b4b76bd49f22fd8faf7a29...v0.3.2)



\* *This Changelog was automatically generated by [github_changelog_generator](https://github.com/github-changelog-generator/github-changelog-generator)*
