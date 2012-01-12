require 'spec_helper'

describe Gravatar::TestCase do
  before { auth_with :password => '123' }
  
  it "should have default email address" do
    self.class.default_email.should_not be_nil
  end
  
  it "should raise errors instead of logging them" do
    grav.rescue_errors.should be_false
  end
  
  it "should use mock responses" do
    mock_response 'grav.test'
    test(:greeting => 'hello').should have_key(:response)
  end
  
  it "should nil out mock responses after use" do
    mock_response 'grav.test'
    test(:greeting => 'hello').should have_key(:response)
    mock_response.should be_nil
  end
  
  it "should remove mock responses from FakeWeb after use" do
    mock_response 'grav.test'
    test(:greeting => 'hello').should have_key(:response)
    FakeWeb.should_not be_registered_uri(:post, grav.url)
  end
  
  it "should not generate grav more than once" do
    grav.should be grav
  end
  
  it "should replace old mock responses with nil" do
    mock_response 'grav.test'
    mock_response nil
    mock_response.should be_nil
  end
end
