require 'spec_helper'

describe Gravatar::Cache do
  subject { Gravatar::Cache.new(new_cache, 30.minutes, "gravatar-specs") }

  context "with a nonexistent cache item" do
    it "should be expired" do
      subject.expired?(:nothing).should be_true
    end

    it "should fire the block" do
      subject.call(:nothing) { @fired = 1 }
      @fired.should == 1
    end

    it "should return nil if no block given" do
      subject.call(:nothing).should be_nil
    end

    it "should return the block value" do
      subject.call(:nothing) { 1 }.should == 1
    end
  end

  context "with a pre-existing cache item" do
    before(:each) { subject.call(:nothing) { 1 } }

    it "should not be expired" do
      subject.expired?(:nothing).should be_false
    end

    it "should not fire the block" do
      subject.call(:nothing) { @fired = 1 }
      @fired.should_not == 1
    end

    it "should return the cached value" do
      subject.call(:nothing) { raise "Block expected not to fire" }.should == 1
    end

    context "that is expired" do
      before(:each) { subject.expire!(:nothing) }

      it "should be expired" do
        subject.expired?(:nothing).should be_true
      end

      it "should fire the block" do
        subject.call(:nothing) { @fired = 1 }
        @fired.should == 1
      end

      it "should return the block value" do
        subject.call(:nothing) { 2 }.should == 2
      end

      it "should return the cached value if there is no block value" do
        subject.call(:nothing).should == 1
      end
    end
  end
end
