require 'bundler'
Bundler.setup

require File.expand_path("../../lib/gravatar", __FILE__)
require 'rspec'

def image_data
  data = File.read(File.expand_path("../fixtures/image.jpg", __FILE__))
  data.respond_to?(:force_encoding) ? data.force_encoding("BINARY") : data
end

require 'fakeweb'
# FakeWeb.allow_net_connect = false
FakeWeb.register_uri(:get, "http://www.gravatar.com/avatar/ef23bdc1f1fb9e3f46843a00e5832d98", :response =>
        "HTTP/1.1 200 OK\nContent-Type: image/jpg\n\n" +image_data)

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

require 'yaml'
$credentials = YAML::load(File.read(File.expand_path("../credentials.yml", __FILE__))).with_indifferent_access
