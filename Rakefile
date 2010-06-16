require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "gravatar-ultimate"
    gem.summary = %Q{A gem for interfacing with the entire Gravatar API: not just images, but the XML-RPC API too!}
    gem.description = %Q{The Ultimate Gravatar Gem!

This gem is used to interface with the entire Gravatar API: it's not just for generating image URLs, but for connecting
to and communicating with the XML-RPC API too! Additionally, it can be used to download the Gravatar image data itself,
rather than just a URL to that data. This saves you the extra step of having to do so.}
    gem.email = "sinisterchipmunk@gmail.com"
    gem.homepage = "http://www.thoughtsincomputation.com/"
    gem.authors = ["Colin MacKenzie IV"]
    gem.add_dependency "sc-core-ext", ">= 1.2.0"
    gem.add_development_dependency "rspec", ">= 1.3.0"
    gem.add_development_dependency "fakeweb", ">= 1.2.8"
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
  Spec::Rake::SpecTask.new(:coverage) do |test|
    test.libs << 'lib' << 'spec'
    test.pattern = "spec/**/*_spec.rb"
    test.verbose = true
    test.rcov = true
    test.rcov_opts = ['--html', '--exclude spec']
  end
rescue LoadError
  task :coverage do
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
