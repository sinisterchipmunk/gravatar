require 'spec_helper'

describe "gravatar cache setup" do
  context "within Rails" do
    before(:each) do
      # We reset it here because we've already set it to MemoryStore for the sake of the majority.
      Gravatar.reset_cache!
      module Rails
      end
    end

    it "should get the default cache instance from Rails" do
      Rails.should_receive(:cache).and_return("a cache object")
      Gravatar.cache
    end

    it "should get the current cache from cache assignment, if any" do
      Gravatar.cache = "a cache object"
      Gravatar.cache.should == "a cache object"
    end
  end

  context "out of Rails" do
    it "should get the default cache from ActiveSupport" do
      Gravatar.cache.should be_kind_of(ActiveSupport::Cache::FileStore)
    end

    it "should get the current cache from cache assignment, if any" do
      Gravatar.cache = "a cache object"
      Gravatar.cache.should == "a cache object"
    end
  end

  after(:each) do
    # We reset it here because we've already fubarred it with the Rails tests.
    Gravatar.reset_cache!

    silence_warnings do
      if defined?(Rails)
        Object.send :remove_const, :Rails
      end
    end
  end
end
