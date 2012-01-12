require 'spec_helper'

describe Gravatar do
  it "should have a valid version number" do
    Gravatar.version.should =~ /^\d+\.\d+\.\d+$/
  end

  it "should allow setting cache duration by instance" do
    grav = Gravatar.new($credentials[:primary_email])
    grav.cache_duration = 10.minutes
    grav.cache_duration.should == 10.minutes
  end

  it "should allow setting cache duration globally" do
    Gravatar.duration = 10.minutes
    Gravatar.new($credentials[:primary_email]).cache_duration.should == 10.minutes
    Gravatar.duration = 30.minutes
  end

  it "should require :email" do
    proc { subject }.should raise_error(ArgumentError)
  end

  context "given :email and :key" do
    subject { Gravatar.new($credentials[:primary_email], $credentials)}
    
    before(:each) do
      # make sure the gravatar has no data, so tests don't taint each other
      subject.user_images.each do |usrimg_hash, (rating, url)|
        subject.delete_user_image!(usrimg_hash)
      end
    end

    context "varying image ratings" do
      [:g, :pg, :r, :x].each do |rating|
        it "should save #{rating}-rated URLs and delete them" do
          subject.save_url!(rating, "http://jigsaw.w3.org/css-validator/images/vcss").should ==
                  "2df7db511c46303983f0092556a1e47c"
          subject.delete_user_image!("2df7db511c46303983f0092556a1e47c").should == true
        end
      end

      it "should raise an ArgumentError given an invalid rating" do
        proc { subject.save_url!(:invalid_rating, "http://jigsaw.w3.org/css-validator/images/vcss") }.should \
          raise_error(ArgumentError)
      end
    end

    it "should return addresses" do
      subject.addresses.should_not be_empty
    end

    it "should test successfully" do
      subject.test(:greeting => 'hello').should have_key(:response)
    end

    it "should save URLs and delete them" do
      subject.save_url!(:g, "http://jigsaw.w3.org/css-validator/images/vcss").should == "2df7db511c46303983f0092556a1e47c"
      subject.delete_user_image!("2df7db511c46303983f0092556a1e47c").should == true
    end

    # Not really the ideal approach but it's a valid test, at least
    it "should save and delete images and associate/unassociate them with accounts" do
      pending
      begin
        subject.save_data!(:g, image_data).should == "23f086a793459fa25aab280054fec1b2"
        subject.use_user_image!("23f086a793459fa25aab280054fec1b2", $credentials[:email]).should ==
                { $credentials[:email] => false }
        # See rdoc for #remove_image! for why we're not checking this.
        subject.remove_image!($credentials[:email])#.should == { $credentials[:email] => true }
        subject.delete_user_image!("23f086a793459fa25aab280054fec1b2").should == true
      ensure
        subject.remove_image!($credentials[:email])
        subject.delete_user_image!("23f086a793459fa25aab280054fec1b2")
      end
    end

    it "should return user images" do
      image_hash = subject.save_data!(:g, image_data)
      subject.use_user_image!(image_hash, $credentials[:email])

      subject.user_images.should include({"23f086a793459fa25aab280054fec1b2"=>
              [:g, "http://en.gravatar.com/userimage/30721149/23f086a793459fa25aab280054fec1b2.jpg"]})
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

    it "should return gravitar image data" do
      Digest::MD5.hexdigest(subject.image_data).should == Digest::MD5.hexdigest(image_data)
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
    
    it "should return gravatar image_url with forcedefault" do
      subject.image_url(:forcedefault => :identicon).should ==
              "http://www.gravatar.com/avatar/5d8c7a8d951a28e10bd7407f33df6d63?forcedefault=identicon"
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
