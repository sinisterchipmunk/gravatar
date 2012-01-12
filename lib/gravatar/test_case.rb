require 'fakeweb'

module Gravatar::TestCase
  class << self
    attr_accessor :fixtures_path
  end
  
  Gravatar::API_METHODS.each do |method_name|
    define_method method_name do |*args, &block|
      allow_net_connect = FakeWeb.allow_net_connect?
      begin
        apply_current_mock!
        grav.send(method_name, *args, &block).tap do
          # mock only lasts 1 request -- this should prevent the wrong
          # mock being used on other APIs
          mock_response nil
        end
      ensure
        FakeWeb.allow_net_connect = allow_net_connect
      end
    end
  end
  
  delegate :auth_with, :email_hash, :to => :grav
  delegate :fixtures_path, :to => "self.class"
  
  def self.included(base)
    base.instance_eval do
      # Sets or gets the default email address to create Gravs with
      # default: "generic@example.com"
      def default_email(new_one = nil)
        !new_one ? @default_email ||= "generic@example.com" : @default_email = new_one
      end
      
      def fixtures_path
        @fixtures_path || Gravatar::TestCase.fixtures_path
      end
      
      def fixtures_path=(a)
        @fixtures_path = a
      end
    end
  end
  
  # Sets the filename of the mock response to be used for the next request.
  # Set to nil to disable mock responses entirely.
  #
  # If name is omitted, the contents of the current mock response, if any, are
  # returned.
  def mock_response(name = :__unassigned)
    if name == :__unassigned
      @mock_response
    else
      if name.nil?
        FakeWeb::Registry.instance.uri_map.each do |uri, methods|
          if uri.to_s == grav.url
            methods.delete :post
          end
        end

        @mock_response = nil
      else
        if fixtures_path.nil?
          raise "fixtures_path is not set! Try setting that first."
        end
        @mock_response = File.read(File.join(fixtures_path, name))
      end
    end
  end
  
  def apply_current_mock!
    if mock_response
      FakeWeb.allow_net_connect = false
      FakeWeb.register_uri :post, grav.url, :response => mock_response
    else
      # don't set to true, instead leave it set to whatever
      # the user has it set to. This way if the user manually
      # sets it to false, they don't have a 4-hour-long WTF.
      # FakeWeb.allow_net_connect = false
    end
  end
  
  # Set or get the Gravatar instance to test against.
  #
  # Examples:
  #   grav        # return the default grav with bogus email
  #   grav(email) # replace with a new grav with given email
  #   grav        # return the current grav with above email
  #
  def grav(*args)
    if args.empty?
      @grav ||= Gravatar.new(self.class.default_email, :rescue_errors => false)
    else
      options = args.extract_options!
      options.reverse_merge! :rescue_errors => false
      @grav = Gravatar.new(*args + [options])
    end
  end
  
  def clear_account(g = grav)
    g.user_images.each do |usrimg_hash, (rating, url)|
      g.delete_user_image!(usrimg_hash)
    end
  end
end
