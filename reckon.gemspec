$:.push File.expand_path("../lib", __FILE__)
require_relative 'lib/reckon/version'

Gem::Specification.new do |s|
  s.name = %q{reckon}
  s.version = Reckon::VERSION
  s.authors = ["Andrew Cantino", "BlackEdder", "Ben Prew"]
  s.email = %q{andrew@iterationlabs.com}
  s.homepage = %q{https://github.com/cantino/reckon}
  s.description = %q{Reckon automagically converts CSV files for use with the command-line accounting tool Ledger.  It also helps you to select the correct accounts associated with the CSV data using Bayesian machine learning.}
  s.summary = %q{Utility for interactively converting and labeling CSV files for the Ledger accounting tool.}
  s.licenses = ['MIT']

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "rspec", ">= 1.2.9"
  s.add_development_dependency "pry", ">= 0.12.2"
  s.add_development_dependency "rantly", "= 1.2.0"
  s.add_runtime_dependency "chronic", ">= 0.3.0"
  s.add_runtime_dependency "highline", "~> 2.0"  # 3.0 replaces readline with reline and breaks reckon
  s.add_runtime_dependency "rchardet", ">= 1.8.0"
  s.add_runtime_dependency "matrix", ">= 0.4.2"
end
