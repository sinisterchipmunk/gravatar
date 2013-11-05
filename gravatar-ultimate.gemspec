# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "gravatar/version"

Gem::Specification.new do |s|
  s.name = %q{gravatar-ultimate}
  s.version = Gravatar::VERSION

  s.authors = ["Colin MacKenzie IV"]
  s.date = %q{2010-08-30}
  s.description = %q{The Ultimate Gravatar Gem!

This gem is used to interface with the entire Gravatar API: it's not just for generating image URLs, but for connecting
to and communicating with the XML-RPC API too! Additionally, it can be used to download the Gravatar image data itself,
rather than just a URL to that data. This saves you the extra step of having to do so.}
  s.email = %q{sinisterchipmunk@gmail.com}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.rdoc"
  ]
  s.files = `git ls-files`.split("\n")
  s.homepage = %q{http://www.thoughtsincomputation.com/}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{A gem for interfacing with the entire Gravatar API: not just images, but the XML-RPC API too!}
  s.test_files = `git ls-files -- spec/*`.split("\n")
  s.executables = `git ls-files -- bin/*`.split("\n")
  
  s.add_dependency('activesupport', '>= 2.3.14')
  s.add_dependency('rack')

  s.add_development_dependency('rspec', ">= 1.3.0")
  s.add_development_dependency('fakeweb', ">= 1.2.8")
  s.add_development_dependency('i18n', '~> 0.6.0')
  s.add_development_dependency('rake', '~> 0.9.2.2')
  s.add_development_dependency('rdoc', '~> 3.11')
  s.add_development_dependency('coveralls')
end
