require "spec_helper"

describe "Dependencies" do
  context "within Rails" do
    before(:each) do
      module ::Rails
        def self.configuration
          return @config if @config
          @config = Object.new
          klass = class << @config; self; end
          klass.instance_eval do
            def gem(*a, &b); end
            public :gem
          end
          @config
        end
      end
    end

    it "should set a Rails gem dependency" do
      Rails.configuration.should_receive(:gem, :with => ["sc-core-ext", ">= 1.2.0"])
      load File.expand_path("../../../../lib/gravatar/dependencies.rb", __FILE__)
    end

    after(:each) { silence_warnings { Object.send(:remove_const, :Rails) } }
  end

  # Don't know how to test the inclusion of sc-core-ext via rubygems, but I suppose there's no reason that should fail.
end
