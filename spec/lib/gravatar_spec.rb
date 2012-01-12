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
          subject.save_url!(rating, "https://github.com/sinisterchipmunk/gravatar/raw/master/spec/fixtures/image.jpg").should ==
                  "23f086a793459fa25aab280054fec1b2"
          subject.delete_user_image!("23f086a793459fa25aab280054fec1b2").should == true
        end
      end

      it "should raise an ArgumentError given an invalid rating" do
        proc { subject.save_url!(:invalid_rating, "https://github.com/sinisterchipmunk/gravatar/raw/master/spec/fixtures/image.jpg") }.should \
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
      subject.save_url!(:g, "https://github.com/sinisterchipmunk/gravatar/raw/master/spec/fixtures/image.jpg").should == "23f086a793459fa25aab280054fec1b2"
      subject.delete_user_image!("23f086a793459fa25aab280054fec1b2").should == true
    end
    
    context "with a user image attached" do
      before do
        @image_hash = subject.save_data!(:g, image_data)
        subject.use_user_image!(@image_hash, $credentials[:email])
      end

      it "should save and delete images and associate/unassociate them with accounts" do
        # See rdoc for #remove_image! for why we're not checking this.
        subject.remove_image!($credentials[:email])#.should == { $credentials[:email] => true }
        subject.delete_user_image!(@image_hash).should == true
      end

      it "should return user images" do
        subject.user_images.should include({@image_hash=>
                [:g, "http://en.gravatar.com/userimage/30721149/#{@image_hash}.jpg"]})
      end

      it "should determine that the email has an avatar" do
        subject.exists?.should be_true
      end
    end

    it "should determine that a fake email does not have an avatar" do
      subject.exists?("not-even-a-valid-email").should be_false
    end

    it "should determine that multiple fake emails do not have avatars" do
      subject.exists?("invalid-1", "invalid-2").should == { "invalid-1" => false, "invalid-2" => false }
    end
  end

  context "given :email" do
    subject { Gravatar.new($credentials[:email]) }
    
    it "should not raise an error" do
      proc { subject }.should_not raise_error(ArgumentError)
    end

    it "should return email_hash" do
      subject.email_hash.should == "ef23bdc1f1fb9e3f46843a00e5832d98"
    end

    it "should return gravatar image_url" do
      subject.image_url.should == "http://www.gravatar.com/avatar/ef23bdc1f1fb9e3f46843a00e5832d98"
    end

    context "with a user image attached" do
      before do
        g = Gravatar.new($credentials[:email], $credentials)
        @image_hash = g.save_data!(:g, image_data)
        g.use_user_image!(@image_hash, $credentials[:email])
      end

      it "should return gravitar image data" do
        Digest::MD5.hexdigest(subject.image_data).should == Digest::MD5.hexdigest(image_data)
      end
    end

    it "should return gravatar image_url with SSL" do
      subject.image_url(:ssl => true).should == "https://secure.gravatar.com/avatar/ef23bdc1f1fb9e3f46843a00e5832d98"
    end

    it "should return gravatar image_url with size" do
      subject.image_url(:s => 512).should == "http://www.gravatar.com/avatar/ef23bdc1f1fb9e3f46843a00e5832d98?s=512"
      subject.image_url(:size => 512).should == "http://www.gravatar.com/avatar/ef23bdc1f1fb9e3f46843a00e5832d98?size=512"
    end

    it "should return gravatar image_url with rating" do
      subject.image_url(:r => 'pg').should == "http://www.gravatar.com/avatar/ef23bdc1f1fb9e3f46843a00e5832d98?r=pg"
      subject.image_url(:rating => 'pg').should == "http://www.gravatar.com/avatar/ef23bdc1f1fb9e3f46843a00e5832d98?rating=pg"
    end

    it "should return gravatar image_url with file type" do
      subject.image_url(:filetype => 'png').should == "http://www.gravatar.com/avatar/ef23bdc1f1fb9e3f46843a00e5832d98.png"
    end

    it "should return gravatar image_url with default image" do
      subject.image_url(:d => "http://example.com/images/example.jpg").should ==
              "http://www.gravatar.com/avatar/ef23bdc1f1fb9e3f46843a00e5832d98?d=http%3A%2F%2Fexample.com%2Fimages%2Fexample.jpg"
      subject.image_url(:default => "http://example.com/images/example.jpg").should ==
              "http://www.gravatar.com/avatar/ef23bdc1f1fb9e3f46843a00e5832d98?default=http%3A%2F%2Fexample.com%2Fimages%2Fexample.jpg"
    end
    
    it "should return gravatar image_url with SSL and default and size and rating" do
      combinations = %w(
        https://secure.gravatar.com/avatar/ef23bdc1f1fb9e3f46843a00e5832d98?default=identicon&size=80&rating=g
        https://secure.gravatar.com/avatar/ef23bdc1f1fb9e3f46843a00e5832d98?size=80&rating=g&default=identicon
        https://secure.gravatar.com/avatar/ef23bdc1f1fb9e3f46843a00e5832d98?size=80&default=identicon&rating=g
        https://secure.gravatar.com/avatar/ef23bdc1f1fb9e3f46843a00e5832d98?rating=g&size=80&default=identicon
      )
      combinations.should include(subject.image_url(:ssl => true, :default => "identicon", :size => 80, :rating => :g))
    end
  end
end
