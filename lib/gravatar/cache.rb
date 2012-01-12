class Gravatar
  # A wrapper around any given Cache object which provides Gravatar-specific helpers. Used internally.
  class Cache
    attr_reader :real_cache, :namespace
    attr_accessor :duration

    def initialize(real_cache, duration, namespace = nil)
      @duration = duration
      @real_cache = real_cache
      @namespace = namespace
    end

    # Provide a series of arguments to be used as a cache key, and a block to be executed when the cache
    # is expired or needs to be populated.
    #
    # Example:
    #   cache = Gravatar::Cache.new(Rails.cache, 30.minutes)
    #   cache.call(:first_name => "Colin", :last_name => "MacKenzie") { call_webservice(with_some_args) }
    #
    def call(*key, &block)
      cached_copy = read_cache(*key)
      if expired?(*key) && block_given?
        yield.tap do |object|
          write_cache(object, *key)
        end
      else
        cached_copy.nil? ? nil : cached_copy[:object]
      end
    end

    # Clears out the entire cache for this object's namespace. This actually removes the objects,
    # instead of simply marking them as expired, so it will be as if the object never existed.
    def clear!
      @real_cache.delete_matched(/^#{Regexp::escape @namespace}/)
    end

    # forces the specified key to become expired
    def expire!(*key)
      unless expired?(*key)
        @real_cache.write(cache_key(*key), { :expires_at => 1.minute.ago, :object => read_cache(*key)[:object] })
      end
    end

    # Returns true if the cached copy is nil or expired based on @duration.
    def expired?(*key)
      cached_copy = read_cache(*key)
      cached_copy.nil? || cached_copy[:expires_at] < Time.now
    end

    # Reads an object from the cache based on the cache key constructed from *key.
    def read_cache(*key)
      @real_cache.read(cache_key(*key))
    end

    # Writes an object to the cache based on th cache key constructed from *key.
    def write_cache(object, *key)
      @real_cache.write(cache_key(*key), { :expires_at => Time.now + duration, :object => object })
    end

    # Constructs a cache key from the specified *args and @namespace.
    def cache_key(*args)
      ActiveSupport::Cache.expand_cache_key(args, @namespace)
    end
  end

  class << self
    def default_cache_instance
      if defined?(Rails)
        Rails.cache
      else
        ActiveSupport::Cache::FileStore.new("tmp/cache")
      end
    end

    def cache
      @cache ||= default_cache_instance
    end

    def cache=(instance)
      @cache = instance
    end

    # How long is a cached object good for? Default is 30 minutes.
    def duration
      @duration ||= 24.hours
    end

    def duration=(duration)
      @duration = duration
    end

    # Resets any changes to the cache and initializes a new cache. If using Rails, the
    # new cache will be the Rails cache.
    def reset_cache!
      @cache = nil
    end
  end
end
