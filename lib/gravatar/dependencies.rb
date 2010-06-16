if defined?(Rails)
  Rails.configuration.gem "sc-core-ext", ">= 1.2.0"
elsif !defined?(Gem)
  require 'rubygems'
  gem 'activesupport', '>= 2.3.5'
  gem 'sc-core-ext', '>= 1.2.0'
end

unless defined?(Rails) # because Rails will load it later and we don't really need it quite yet.
  unless defined?(ActiveSupport::Cache)
    require 'active_support'
  end

  unless defined?(ScCoreExt)
    require 'sc-core-ext'
  end
end

# The rest of this is core Ruby stuff so it's safe to load immediately, even if Rails is running the show.
require 'open-uri'
require "digest/md5"
require 'xmlrpc/client'
require 'base64'
