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
    
    context "after clearing the cache" do
      before { subject.clear! }
      it "should be nil" do
        subject.call(:nothing) { 2 }.should == 2
      end
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

      context "in the event of an error while refreshing" do
        before(:each) { subject.logger = StringIO.new("") }
        
        it "should recover" do
          proc { subject.call(:nothing) { raise "something bad happened" } }.should_not raise_error
        end

        it "should return the cached copy" do
          subject.call(:nothing) { raise "something bad happened" }.should == 1
        end

        context "its logger" do
          before(:each) { subject.logger = Object.new }

          it "should log it if #error is available" do
            subject.logger.stub(:error => nil)
            subject.logger.should_receive(:error).and_return(nil)
            subject.call(:nothing) { raise "something bad happened" }
          end

          it "should log it if #write is available" do
            subject.logger.stub(:write => nil)
            subject.logger.should_receive(:write).and_return(nil)
            subject.call(:nothing) { raise "something bad happened" }
          end

          it "should re-raise the error if no other methods are available" do
            proc { subject.call(:nothing) { raise "something bad happened" } }.should raise_error
          end
        end

        it "should provide access to the cached copy" do
          subject.cached(:nothing).should == 1
        end
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
