require 'bundler'
Bundler::GemHelper.install_tasks
Bundler.setup

require 'rspec/core/rake_task'
desc "Run all specs"
RSpec::Core::RakeTask.new

begin
  gem 'rcov'
  require 'rcov/rcovtask'
  RSpec::Core::RakeTask.new(:coverage) do |test|
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

task :default => :spec

require 'rdoc/task'
RDoc::Task.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "gravatar #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
