require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "reckon"
    gem.summary = %Q{Utility for interactively converting and labeling CSV files for the Ledger accounting tool.}
    gem.description = %Q{Reckon automagically converts CSV files for use with the command-line accounting tool Ledger.  It also helps you to select the correct accounts associated with the CSV data using Bayesian machine learning.}
    gem.email = "andrew@iterationlabs.com"
    gem.homepage = "http://github.com/iterationlabs/reckon"
    gem.authors = ["Andrew Cantino"]
    gem.add_development_dependency "rspec", "1.3.1"
    gem.add_development_dependency "jeweler"
    gem.add_dependency('fastercsv', '>= 1.5.1')
    gem.add_dependency('chronic', '>= 0.3.0')
    gem.add_dependency('highline', '>= 1.5.2')
    gem.add_dependency('terminal-table', '>= 1.4.2')
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :spec => :check_dependencies

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "reckon #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
