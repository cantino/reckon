# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

require 'reckon/version'
Gem::Specification.new do |s|
  s.name = %q{reckon}
  s.version = Reckon::VERSION
  s.authors = ["Andrew Cantino"]
  s.email = %q{andrew@iterationlabs.com}
  s.homepage = %q{https://github.com/cantino/reckon}
  s.description = %q{Reckon automagically converts CSV files for use with the command-line accounting tool Ledger.  It also helps you to select the correct accounts associated with the CSV data using Bayesian machine learning.}
  s.summary = %q{Utility for interactively converting and labeling CSV files for the Ledger accounting tool.}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "rspec", ">= 1.2.9"
  s.add_development_dependency "pry"
  s.add_runtime_dependency "fastercsv", ">= 1.5.1"
  s.add_runtime_dependency "chronic", ">= 0.3.0"
  s.add_runtime_dependency "highline", ">= 1.5.2"
  s.add_runtime_dependency "terminal-table", ">= 1.4.2"
  s.add_runtime_dependency "charlock_holmes", ">= 0.6.9"
end

