require 'spec_helper'

describe Gravatar do
  it "should require :email" do
    proc { subject }.should raise_error(ArgumentError)
  end

  context "given :email and :key" do
    subject { Gravatar.new("sinisterchipmunk@gmail.com", :apikey => "567c979bdde3")}

    it "should return addresses" do
      subject.addresses.should_not be_empty
    end

    it "should test successfully" do
      subject.test(:greeting => 'hello').should have_key(:response)
    end

    it "should return user images" do
      subject.user_images.should == {"fe9dee44a1df19967db30a04083722d5"=>
              ["0", "http://en.gravatar.com/userimage/14612723/fe9dee44a1df19967db30a04083722d5.jpg"]}
    end

    it "should determine that the user exists" do
      subject.exists?.should be_true
    end

    it "should determine that a fake user does not exist" do
      subject.exists?("not-even-a-valid-email").should be_false
    end

    it "should determine that multiple fake users do not exist" do
      subject.exists?("invalid-1", "invalid-2").should == { "invalid-1" => false, "invalid-2" => false }
    end
  end

  context "given :email" do
    subject { Gravatar.new("sinisterchipmunk@gmail.com") }

    it "should not raise an error" do
      proc { subject }.should_not raise_error(ArgumentError)
    end

    it "should return email_hash" do
      subject.email_hash.should == "5d8c7a8d951a28e10bd7407f33df6d63"
    end

    it "should return gravatar image_url" do
      subject.image_url.should == "http://www.gravatar.com/avatar/5d8c7a8d951a28e10bd7407f33df6d63"
    end

    it "should return gravatar image_url with SSL" do
      subject.image_url(:ssl => true).should == "https://secure.gravatar.com/avatar/5d8c7a8d951a28e10bd7407f33df6d63"
    end

    it "should return gravatar image_url with size" do
      subject.image_url(:size => 512).should == "http://www.gravatar.com/avatar/5d8c7a8d951a28e10bd7407f33df6d63?size=512"
    end

    it "should return gravatar image_url with rating" do
      subject.image_url(:rating => 'pg').should == "http://www.gravatar.com/avatar/5d8c7a8d951a28e10bd7407f33df6d63?rating=pg"
    end

    it "should return gravatar image_url with file type" do
      subject.image_url(:filetype => 'png').should == "http://www.gravatar.com/avatar/5d8c7a8d951a28e10bd7407f33df6d63.png"
    end

    it "should return gravatar image_url with default image" do
      subject.image_url(:default => "http://example.com/images/example.jpg").should ==
              "http://www.gravatar.com/avatar/5d8c7a8d951a28e10bd7407f33df6d63?default=http%3A%2F%2Fexample.com%2Fimages%2Fexample.jpg"
    end

    it "should return gravatar image_url with SSL and default and size and rating" do
      combinations = %w(
        https://secure.gravatar.com/avatar/5d8c7a8d951a28e10bd7407f33df6d63?default=identicon&size=80&rating=g
        https://secure.gravatar.com/avatar/5d8c7a8d951a28e10bd7407f33df6d63?size=80&rating=g&default=identicon
        https://secure.gravatar.com/avatar/5d8c7a8d951a28e10bd7407f33df6d63?size=80&default=identicon&rating=g
        https://secure.gravatar.com/avatar/5d8c7a8d951a28e10bd7407f33df6d63?rating=g&size=80&default=identicon
      )
      combinations.should include(subject.image_url(:ssl => true, :default => "identicon", :size => 80, :rating => :g))
    end
  end
end
