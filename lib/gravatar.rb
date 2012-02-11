require 'active_support'
require 'active_support/core_ext'
require File.expand_path('../gravatar/dependencies', __FILE__)
require File.expand_path("../gravatar/cache", __FILE__)

# ==== Errors ====
#
# Errors usually come with a number and human readable text. Generally the text should be followed whenever possible,
# but a brief description of the numeric error codes are as follows:
#
#     -7  Use secure.gravatar.com
#     -8  Internal error
#     -9  Authentication error
#     -10 Method parameter missing
#     -11 Method parameter incorrect
#     -100  Misc error (see text)
#
class Gravatar
  API_METHODS = [
    :exists?, :addresses, :user_images, :save_data!, :save_image!, :save_url!, :use_image!, :use_user_image!,
    :remove_image!, :delete_user_image!, :test, :image_url, :image_data, :signup_url
  ]
  autoload :TestCase, File.expand_path('gravatar/test_case', File.dirname(__FILE__))
  
  attr_reader :email, :api
  
  delegate :rescue_errors, :rescue_errors=, :to => :cache

  # Creates a new instance of Gravatar. Valid options include:
  #   :password                   => the password for this account, to be used instead of :api_key (don't supply both)
  #   :api_key or :apikey or :key => the API key for this account, to be used instead of :password (don't supply both)
  #   :duration                   => the cache duration to use for this instance
  #   :logger                     => the logger to use for this instance
  #
  # Note that :password and :api_key are both optional. If omitted, no web services will be available but this
  # user's Gravatar image can still be constructed using #image_uri or #image_data.
  #
  def initialize(email, options = {})
    raise ArgumentError, "Expected :email" unless email
    @options = options || {}
    @email = email
    
    pw_or_key = auth.keys.first || :none
    @cache = Gravatar::Cache.new(self.class.cache, options[:duration] || self.class.duration,
                                 "gravatar-#{email_hash}-#{pw_or_key}", options[:logger] || self.class.logger)
    self.rescue_errors = options[:rescue_errors]

    self.auth_with auth unless auth.empty?
  end
  
  def host
    "secure.gravatar.com"
  end
  
  def url
    File.join("https://#{host}", path)
  end
  
  def path
    "/xmlrpc?user=#{email_hash}"
  end

  # The duration of the cache for this instance of Gravatar, independent of any other instance
  def cache_duration
    cache.duration
  end

  # Sets the duration of the cache for this instance of Gravatar, independent of any other instance
  def cache_duration=(time)
    cache.duration = time
  end

  # Check whether one or more email addresses have corresponding avatars. If no email addresses are
  # specified, the one associated with this object is used.
  #
  # Returns: Boolean for a single email address; a hash of emails => booleans for multiple addresses.
  #
  # This method is cached for up to the value of @duration or Gravatar.duration.
  def exists?(*emails)
    hashed_emails = normalize_email_addresses(emails)
    cache('exists', hashed_emails) do
      hash = call('grav.exists', :hashes => hashed_emails)
      if hash.length == 1
        boolean(hash.values.first)
      else
        dehashify_emails(hash, emails) { |value| boolean(value) }
      end
    end
  end

  # Gets a list of addresses for this account, returning a hash following this format:
  #  {
  #    address => {
  #      :rating => rating,
  #      :userimage => userimage,
  #      :userimage_url => userimage_url
  #    }
  #  }
  #
  # This method is cached for up to the value of @duration or Gravatar.duration.
  def addresses
    cache('addresses') do
      call('grav.addresses').inject({}) do |hash, (address, info)|
        hash[address] = info.merge(:rating => rating(info[:rating]))
        hash
      end
    end
  end
  
  # Returns a hash of user images for this account in the following format:
  #   { user_img_hash => [rating, url] }
  #
  # This method is cached for up to the value of @duration or Gravatar.duration.
  def user_images
    cache('user_images') do
      call('grav.userimages').inject({}) do |hash, (key, array)|
        hash[key] = [rating(array.first), array.last]
        hash
      end
    end
  end

  # Saves binary image data as a userimage for this account and returns the ID of the image.
  #
  # This method is not cached.
  def save_data!(rating, data)
    call('grav.saveData', :data => Base64.encode64(data), :rating => _rating(rating))
  end
  alias save_image! save_data!

  # Read an image via its URL and save that as a userimage for this account, returning true or false
  #
  # This method is not cached.
  def save_url!(rating, url)
    call('grav.saveUrl', :url => url, :rating => _rating(rating))
  end

  # Use a userimage as a gravatar for one or more addresses on this account. Returns a hash:
  #   { email_address => true/false }
  #
  # This method is not cached.
  #
  # This method will clear out the cache, since it may have an effect on what the API methods respond with.
  def use_user_image!(image_hash, emails)
    emails = [emails] unless emails.is_a?(Array)
    hash = call('grav.useUserimage', :userimage => image_hash, :addresses => emails)
    expire_cache!
    return hash
  end
  alias use_image! use_user_image!

  # Remove the userimage associated with one or more email addresses. Returns a hash of booleans.
  #   NOTE: This appears to always return false, even when it is really removing an image. If you
  #   know what the deal with that is, drop me a line so I can update this documentation!
  #
  # This method is not cached.
  #
  # This method will clear out the cache, since it may have an effect on what the API methods respond with.
  def remove_image!(emails)
    emails = [emails] unless emails.is_a?(Array)
    hash = call('grav.removeImage', :addresses => emails)
    expire_cache!
    return hash
  end

  # Remove a userimage from the account and any email addresses with which it is associated. Returns
  # true or false.
  #
  # This method is not cached.
  #
  # This method will clear out the cache, since it may have an effect on what the API methods respond with.
  def delete_user_image!(userimage)
    boolean(call('grav.deleteUserimage', :userimage => userimage)).tap do
      expire_cache!
    end
  end

  # Runs a simple Gravatar test. Useful for debugging. Gravatar will echo back any arguments you pass.
  # This method is not cached.
  def test(hash)
    call('grav.test', hash)
  end

  # Returns the MD5 hash for the specified email address, or the one associated with this object.
  def email_hash(email = self.email)
    Digest::MD5.hexdigest(email.downcase.strip)
  end

  # Returns the URL for this user's gravatar image. Options include:
  #
  #   :ssl     or :secure    if true, HTTPS will be used instead of HTTP. Default is false.
  #   :rating  or :r         a rating threshold for this image. Can be one of [ :g, :pg, :r, :x ]. Default is :g.
  #   :size    or :s         a size for this image. Can be anywhere between 1 and 512. Default is 80.
  #   :default or :d         a default URL for this image to display if the specified user has no image;
  #                          or this can be one of [ :identicon, :monsterid, :wavatar, 404 ]. By default a generic
  #                          Gravatar image URL will be returned.
  #   :filetype or :ext      an extension such as :jpg or :png. Default is omitted.
  #   :forcedefault or :f    force a default image and ignore the user's specified image. Can be one of
  #                          [ :identicon, :monsterid, :wavatar, 404 ].
  #
  # See http://en.gravatar.com/site/implement/url for much more detailed information.
  def image_url(options = {})
    secure = options[:ssl] || options[:secure]
    proto = "http#{secure ? 's' : ''}"
    sub = secure ? "secure" : "www"

    "#{proto}://#{sub}.gravatar.com/avatar/#{email_hash}#{extension_for_image(options)}#{query_for_image(options)}"
  end

  # Returns the URL for Gravatar's signup form, with the user's email pre-filled. Options include:
  #
  #   :locale                if non-nil, wil be used to prefix the URL. Example: :en
  def signup_url(options = {})
    locale_prefix = options[:locale] ? "#{options[:locale]}." : ''

    "https://#{locale_prefix}gravatar.com/site/signup/#{CGI.escape(email)}"
  end

  # Returns the image data for this user's gravatar image. This is the same as reading the data at #image_url. See
  # that method for more information.
  #
  # This method is cached for up to the value of @duration or Gravatar.duration.
  def image_data(options = {})
    url = image_url(options)
    cache(url) { OpenURI.open_uri(URI.parse(url)).read }
  end

  # If no arguments are given, the cache object for this instance is returned. Otherwise, the arguments
  # are passed into Gravatar::Cache#cache.
  def cache(*key, &block)
    if key.empty? and not block_given?
      @cache
    else
      @cache.call(*key, &block)
    end
  end

  def expire_cache!
    cache.clear!
  end

  def dehashify_emails(response, emails)
    hashed_emails = emails.collect { |email| email_hash(email) }
    response.inject({}) do |hash, (hashed_email, value)|
      value = yield(value) if value
      email = emails[hashed_emails.index(hashed_email)]
      hash[email] = value
      hash
    end
  end

  def normalize_email_addresses(addresses)
    addresses.flatten!
    addresses << @email if addresses.empty?
    addresses.map { |email| email_hash(email) }
  end

  def rating(i)
    case i
      when -1, '-1' then :unknown
      when 0, '0' then :g
      when 1, '1' then :pg
      when 2, '2' then :r
      when 3, '3' then :x
      when :unknown then -1
      when :g  then 0
      when :pg then 1
      when :r  then 2
      when :x  then 3
      else raise ArgumentError, "Unexpected rating index: #{i} (expected between 0..3)"
    end
  end
  alias _rating rating

  def boolean(i)
    i.kind_of?(Numeric) ? i != 0 : i
  end

  def call(name, args_hash = {})
    raise "No authentication data given" unless @api
    r = @api.call(name, auth.merge(args_hash))
    r = r.with_indifferent_access if r.kind_of?(Hash)
    r
  end
  
  # Authenticates with the given API key or password, returning self.
  def auth_with(options)
    @options.delete(:apikey)
    @options.delete(:api_key)
    @options.delete(:key)
    @options.merge! options
    if !auth.empty?
      @api = XMLRPC::Client.new(host, path, 443, nil, nil, nil, nil, true)
    end
    self
  end

  def auth
    api_key ? {:apikey => api_key} : (password ? {:password => password} : {})
  end

  def api_key
    options[:apikey] || options[:api_key] || options[:key]
  end

  def password
    options[:password]
  end

  def options
    @options
  end

  def query_for_image(options)
    query = ''
    [:rating, :size, :default, :forcedefault, :r, :s, :d, :f].each do |key|
      if options.key?(key)
        query.blank? ? query.concat("?") : query.concat("&")
        query.concat("#{key}=#{CGI::escape options[key].to_s}")
      end
    end
    query
  end

  def extension_for_image(options)
    options.key?(:filetype) || options.key?(:ext) ? "." + (options[:filetype] || options[:ext] || "jpg").to_s : ""
  end
end

