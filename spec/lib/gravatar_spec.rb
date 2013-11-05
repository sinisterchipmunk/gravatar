require 'spec_helper'

describe Gravatar do
  default_email $credentials[:primary_email]
  before { grav.auth_with(:password => $credentials[:password]) }
  before { mock_response nil }
  
  it "should allow setting cache duration by instance" do
    grav.cache_duration = 10.minutes
    grav.cache_duration.should == 10.minutes
  end

  it "should allow setting cache duration globally" do
    Gravatar.duration = 10.minutes
    Gravatar.new($credentials[:primary_email]).cache_duration.should == 10.minutes
    Gravatar.duration = 30.minutes
  end

  it "should require :email" do
    proc { Gravatar.new(nil, :rescue_errors => false) }.should raise_error(ArgumentError)
  end

  context "given :email and :key" do
    before { grav $credentials[:primary_email], $credentials }

    context "varying image ratings" do
      [:g, :pg, :r, :x].each do |rating|
        it "should save #{rating}-rated URLs and delete them" do
          mock_response "grav.saveUrl"
          save_url!(rating, "https://github.com/sinisterchipmunk/gravatar/raw/master/spec/fixtures/image.jpg").should ==
                  "fed25d74d58274248095ca6b2fe2beff"
          
          mock_response "grav.deleteUserimage"
          delete_user_image!("fed25d74d58274248095ca6b2fe2beff").should == true
        end
      end

      it "should raise an ArgumentError given an invalid rating" do
        proc { save_url!(:invalid_rating, "https://github.com/sinisterchipmunk/gravatar/raw/master/spec/fixtures/image.jpg") }.should \
          raise_error(ArgumentError)
      end
    end

    it "should return addresses" do
      mock_response 'grav.addresses'
      addresses.should_not be_empty
    end

    it "should test successfully" do
      mock_response 'grav.test'
      test(:greeting => 'hello').should have_key(:response)
    end

    it "should save URLs and delete them" do
      mock_response 'grav.saveUrl'
      save_url!(:g, "https://github.com/sinisterchipmunk/gravatar/raw/master/spec/fixtures/image.jpg").should == "fed25d74d58274248095ca6b2fe2beff"
      
      mock_response 'grav.deleteUserimage'
      delete_user_image!("fed25d74d58274248095ca6b2fe2beff").should == true
    end
    
    context "with a user image attached" do
      before do
        mock_response 'grav.saveData'
        @image_hash = save_data!(:g, mock_image_data)
        
        mock_response 'grav.useUserimage'
        use_user_image!(@image_hash, $credentials[:email])
        
        @image_hash = 'fed25d74d58274248095ca6b2fe2beff'
      end

      it "should save and delete images and associate/unassociate them with accounts" do
        mock_response 'grav.removeImage'
        remove_image!($credentials[:email]).should == { $credentials[:email] => true }

        mock_response 'grav.deleteUserimage'
        delete_user_image!('image_hash').should == true
      end

      it "should return user images" do
        mock_response 'grav.userimages'
        user_images.should include({@image_hash=>
                [:g, "http://en.gravatar.com/userimage/30721149/#{@image_hash}.jpg"]})
      end

      it "should determine that the email has an avatar" do
        mock_response 'grav.exists'
        exists?.should be_true
      end
    end

    it "should determine that a fake email does not have an avatar" do
      mock_response 'grav.exists.invalid'
      exists?("not-even-a-valid-email").should be_false
    end

    it "should determine that multiple fake emails do not have avatars" do
      mock_response 'grav.exists.multiple_invalid'
      exists?("invalid-1", "invalid-2").should == { "invalid-1" => false, "invalid-2" => false }
    end
  end

  context "given :email" do
    before { grav $credentials[:email] }
    
    it "should not raise an error" do
      proc { grav }.should_not raise_error
    end

    it "should return email_hash" do
      email_hash.should == "ef23bdc1f1fb9e3f46843a00e5832d98"
    end

    it "should return gravatar image_url" do
      image_url.should == "http://www.gravatar.com/avatar/ef23bdc1f1fb9e3f46843a00e5832d98"
    end

    context "with a user image attached" do
      before do
        grav $credentials[:email], $credentials

        mock_response 'grav.saveData'
        @image_hash = save_data!(:g, mock_image_data)
        
        mock_response 'grav.useUserimage'
        use_user_image!(@image_hash, $credentials[:email])
      end

      it "should return gravitar image data" do
        Digest::MD5.hexdigest(grav.image_data).should == Digest::MD5.hexdigest(mock_image_data)
      end
    end

    it "should return gravatar image_url with SSL" do
      image_url(:ssl => true).should == "https://secure.gravatar.com/avatar/ef23bdc1f1fb9e3f46843a00e5832d98"
    end

    it "should return gravatar image_url with size" do
      image_url(:s => 512).should == "http://www.gravatar.com/avatar/ef23bdc1f1fb9e3f46843a00e5832d98?s=512"
      image_url(:size => 512).should == "http://www.gravatar.com/avatar/ef23bdc1f1fb9e3f46843a00e5832d98?size=512"
    end

    it "should return gravatar image_url with rating" do
      image_url(:r => 'pg').should == "http://www.gravatar.com/avatar/ef23bdc1f1fb9e3f46843a00e5832d98?r=pg"
      image_url(:rating => 'pg').should == "http://www.gravatar.com/avatar/ef23bdc1f1fb9e3f46843a00e5832d98?rating=pg"
    end

    it "should return gravatar image_url with file type" do
      image_url(:filetype => 'png').should == "http://www.gravatar.com/avatar/ef23bdc1f1fb9e3f46843a00e5832d98.png"
    end

    it "should return gravatar image_url with default image" do
      image_url(:d => "http://example.com/images/example.jpg").should ==
              "http://www.gravatar.com/avatar/ef23bdc1f1fb9e3f46843a00e5832d98?d=http%3A%2F%2Fexample.com%2Fimages%2Fexample.jpg"
      image_url(:default => "http://example.com/images/example.jpg").should ==
              "http://www.gravatar.com/avatar/ef23bdc1f1fb9e3f46843a00e5832d98?default=http%3A%2F%2Fexample.com%2Fimages%2Fexample.jpg"
    end
    
    it "should return gravatar image_url with forcedefault" do
      image_url(:f => :identicon).should ==
              "http://www.gravatar.com/avatar/ef23bdc1f1fb9e3f46843a00e5832d98?f=identicon"
      image_url(:forcedefault => :identicon).should ==
              "http://www.gravatar.com/avatar/ef23bdc1f1fb9e3f46843a00e5832d98?forcedefault=identicon"
    end

    it "should return gravatar image_url with SSL and default and size and rating" do
      combinations = %w(
        https://secure.gravatar.com/avatar/ef23bdc1f1fb9e3f46843a00e5832d98?default=identicon&size=80&rating=g
        https://secure.gravatar.com/avatar/ef23bdc1f1fb9e3f46843a00e5832d98?size=80&rating=g&default=identicon
        https://secure.gravatar.com/avatar/ef23bdc1f1fb9e3f46843a00e5832d98?size=80&default=identicon&rating=g
        https://secure.gravatar.com/avatar/ef23bdc1f1fb9e3f46843a00e5832d98?rating=g&size=80&default=identicon
      )
      combinations.should include(image_url(:ssl => true, :default => "identicon", :size => 80, :rating => :g))
    end
    
    it "should return gravatar signup_url" do
      signup_url.should == "https://gravatar.com/site/signup/gravatartest123%40gmail.com"
    end

    it "should return gravatar signup_url with locale" do
      signup_url(:locale => :en).should == "https://en.gravatar.com/site/signup/gravatartest123%40gmail.com"      
    end
  end
end
