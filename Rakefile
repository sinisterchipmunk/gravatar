require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "gravatar"
    gem.summary = %Q{A gem for interfacing with the entire Gravatar API: not just images, but the XML-RPC API too!}
    gem.description = %Q{TODO: longer description of your gem}
    gem.email = "sinisterchipmunk@gmail.com"
    gem.homepage = "http://github.com/sinisterchipmunk/gravatar"
    gem.authors = ["Colin MacKenzie IV"]
    gem.add_dependency "sc-core-ext", ">= 1.2.0"
    gem.add_development_dependency "rspec", ">= 0"
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:test) do |test|
  test.libs << 'lib' << 'spec'
  test.pattern = 'spec/**/*_spec.rb'
  test.verbose = true
end

desc "Run all specs"
task :spec => :test

begin
  gem 'rcov'
  require 'rcov/rcovtask'
  Spec::Rake::SpecTask.new(:rcov) do |test|
    test.libs << 'lib' << 'spec'
    test.pattern = "spec/**/*_spec.rb"
    test.verbose = true
    test.rcov = true
    test.rcov_opts = ['--html', '--exclude spec']
  end
=begin
  Rcov::RcovTask.new do |test|
    test.libs << 'spec'
    test.rcov_opts = ['--html']
    test.pattern = 'spec/**/*_spec.rb'
    test.verbose = true
  end
=end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => :check_dependencies

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "gravatar #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
