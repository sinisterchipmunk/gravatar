require 'bundler'
Bundler.setup

require 'coveralls'
Coveralls.wear!

require File.expand_path('../environments/rails', File.dirname(__FILE__))
require File.expand_path("../../lib/gravatar", __FILE__)
require 'rspec'

def mock_image_data
  data = File.read(File.expand_path("../fixtures/image.jpg", __FILE__))
  data.respond_to?(:force_encoding) ? data.force_encoding("BINARY") : data
end

require 'fakeweb'

RSpec.configure do |config|
  config.before do
    FakeWeb.allow_net_connect = false
    FakeWeb.register_uri(:get, "http://www.gravatar.com/avatar/ef23bdc1f1fb9e3f46843a00e5832d98", :response =>
            "HTTP/1.1 200 OK\nContent-Type: image/jpg\n\n" +mock_image_data)
  end

  config.after do
    FakeWeb.allow_net_connect = true
  end
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

Gravatar::TestCase.fixtures_path = File.expand_path("fixtures/responses", File.dirname(__FILE__))

RSpec.configure do |c|
  c.include Gravatar::TestCase
end

class XMLRPC::Client
  def set_debug
    @http.set_debug_output $stderr
  end
  alias _initialize initialize
  def initialize(*a,&b) _initialize(*a,&b); set_debug; end
end

require 'yaml'
creds = File.expand_path("../credentials.yml", __FILE__)
if File.file?(creds)
  $credentials = YAML::load(File.read(creds)).with_indifferent_access
else
  $credentials = {
    :primary_email => 'gravatartest123@gmail.com',
    :email => 'gravatartest123@gmail.com',
    :password => 'aPassword',
    :email_hash => 'anEmailHash'
  }.with_indifferent_access
end
