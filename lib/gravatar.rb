require 'rubygems'
require "digest/md5"
require 'sc-core-ext'
require 'xmlrpc/client'

# Connecting
# API Endpoint: https://secure.gravatar.com/xmlrpc?user=[email_hash]
#
# It is mandatory that you connect to secure.gravatar.com, and that you do so over HTTPS. This is for the safety of our
# mutual users. The email_hash GET parameter is the md5 hash of the users email address after it has been lowercased,
# and trimmed.
#
# Authentication
# User authentication happens at the api method level. You will pass to the method call an apikey or password parameter.
# The data for these parameters will be passed in plain text. Only one valid form of authentication is necessary. The
# apikey and password params are always stripped from the arguments before the methods begin their processing. For this
# reason you should expect not to see either of these values returned from the grav.test method.
#
# Errors
# Errors usually come with a number and human readable text. Generally the text should be followed whenever possible,
# but a brief description of the numeric error codes are as follows:
#
#     -7	Use secure.gravatar.com
#     -8	Internal error
#     -9	Authentication error
#     -10	Method parameter missing
#     -11	Method parameter incorrect
#     -100	Misc error (see text)
#
class Gravatar
  attr_reader :email

  def initialize(email, options = {})
    raise ArgumentError, "Expected :email" unless email
    @options = options || {}

    @email = email
    if !auth.empty?
      @api = XMLRPC::Client.new("secure.gravatar.com", "/xmlrpc?user=#{email_hash}", 443, nil, nil, nil, nil, true)
    end
  end

  # Check whether one or more email addresses have corresponding avatars. If no email addresses are
  # specified, the one associated with this object is used.
  #
  # Returns: Boolean for a single email address; a hash of emails => booleans for multiple addresses.
  def exists?(*emails)
    hashed_emails = normalize_email_addresses(emails)
    hash = call('grav.exists', :hashes => hashed_emails)
    if hash.length == 1
      boolean(hash.values.first)
    else
      dehashify_emails(hash, emails) { |value| boolean(value) }
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
  def addresses
    call('grav.addresses')
  end

  # Returns a hash of user images for this account in the following format:
  #   { user_img_hash => [rating, url] }
  def user_images
    call('grav.userimages')
  end

  # Saves binary image data as a userimage for this account
  def save_data!(rating, data)
    boolean(call('grav.saveData', :data => Base64.encode64(data), :rating => self.rating(rating)))
  end
  alias save_image! save_data!

  # Read an image via its URL and save that as a userimage for this account
  def save_url!(rating, url)
    boolean(call('grav.saveUrl', :url => url, :rating => self.rating(rating)))
  end

  def use_user_image!(image_hash, *email_addresses)
    hashed_email_addresses = normalize_email_addresses(email_addresses)
    hash = call('grav.useUserimage', :userimage => image_hash, :addresses => hashed_email_addresses)
    dehashify_emails(hash, email_addresses) { |value| boolean(value) }
  end
  alias use_image! use_user_image!

  def remove_image!(*emails)
    hashed_email_addresses = normalize_email_addresses(emails)
    hash = call('grav.removeImage', :addresses => hashed_email_addresses)
    dehashify_emails(hash, emails) { |value| boolean(value) }
  end

  def delete_user_image!(userimage)
    boolean(call('grav.deleteUserimage', :userimage => userimage))
  end

  def test(hash)
    call('grav.test', hash)
  end

  def email_hash(email = self.email)
    Digest::MD5.hexdigest(email.downcase.strip)
  end

  def image_url(options = {})
    proto = "http#{options[:ssl] ? 's' : ''}"
    sub = options[:ssl] ? "secure" : "www"

    "#{proto}://#{sub}.gravatar.com/avatar/#{email_hash}#{extension_for_image(options)}#{query_for_image(options)}"
  end

  private
  def dehashify_emails(response, emails)
    response.inject({}) do |hash, (hashed_email, value)|
      value = yield(value) if value
      begin
        email = emails[response.keys.index(hashed_email)]
      rescue TypeError
        raise TypeError, "Could not find key index of #{hashed_email} in #{hash.keys.inspect}"
      end
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
      when 0, '0' then :g
      when 1, '1' then :pg
      when 2, '2' then :r
      when 3, '3' then :x
      when :g  then 0
      when :pg then 1
      when :r  then 2
      when :x  then 3
      else raise "Unexpected rating index: #{i} (expected between 0..3)"
    end
  end

  def boolean(i)
    i != 0
  end

  def call(name, args_hash = {})
    @api.call(name, auth.merge(args_hash)).with_indifferent_access
  end

  def auth
    api_key ? {:apikey => api_key} : {:password => password}
  end

  def api_key
    options[:apikey] || options[:api_key]
  end

  def password
    options[:password]
  end

  def options
    @options
  end

  def query_for_image(options)
    query = ''
    [:rating, :size, :default].each do |key|
      if options.key?(key)
        query.blank? ? query.concat("?") : query.concat("&")
        query.concat("#{key}=#{CGI::escape options[key].to_s}")
      end
    end
    query
  end

  def extension_for_image(options)
    options.key?(:filetype) ? "." + (options[:filetype] || "jpg").to_s : ""
  end
end
