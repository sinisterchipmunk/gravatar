# The rest of this is core Ruby stuff so it's safe to load immediately, even if Rails is running the show.
require 'cgi'
require 'open-uri'
require "digest/md5"
require 'xmlrpc/client'
require 'base64'
