require File.expand_path("../../lib/gravatar", __FILE__)
unless defined?(Spec)
  gem 'rspec'
  require 'spec'
end

def new_cache
  ActiveSupport::Cache::MemoryStore.new
end

Gravatar.cache = new_cache

class Net::HTTP
  alias_method :original_initialize, :initialize
  def initialize(*args, &block)
    original_initialize(*args, &block)
    @ssl_context = OpenSSL::SSL::SSLContext.new
    @ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
  end
end

$credentials = YAML::load(File.read(File.expand_path("../credentials.yml", __FILE__))).with_indifferent_access
