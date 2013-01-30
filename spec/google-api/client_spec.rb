require 'spec_helper'

describe GoogleAPI::Client do

  let(:object) { User.new }

  subject { GoogleAPI::Client.new(object) }

  before do
    GoogleAPI.configure do |config|
      config.client_id = 'test id'
      config.client_secret = 'test secret'
      config.encryption_key = 'encryption key'
    end
    GoogleAPI.logger.stub(:info)
    object.authenticated = true
    subject.client.connection = TEST_CONNECTION
  end

  its(:object) { should == object }
  its(:client) { should be_an_instance_of(::OAuth2::Client) }

  describe "#initialize" do
    it "should raise NoMethodError if the object isn't oauthable" do
      expect { GoogleAPI::Client.new(Class.new) }.to raise_error(NoMethodError)
    end

    it "should raise ArgumentError if the object isn't OAuth2 authenticated" do
      object.authenticated = false
      expect { GoogleAPI::Client.new(object) }.to raise_error(ArgumentError)
    end
  end

  describe "#access_token" do
    it "should call to the OAuth2 Access Token class" do
      subject.access_token.token.should == object.oauth_hash[:access_token]
    end

    context "when the access token is expired" do
      before { object.expires_at = Time.now - 86400 }

      it "should call refresh on the OAuth2 Access Token" do
        stubbed_access_token = Class.new
        stubbed_access_token.stub(:token).and_return('test token')
        ::OAuth2::AccessToken.any_instance.should_receive(:refresh!).and_return(stubbed_access_token)
        subject.access_token
      end

      it "should update the object's stored OAuth information" do
        object.should_receive(:update_oauth!)
        subject.access_token
      end
    end

    context "when the access token is fresh" do
      it "should not try and refresh the token again" do
        ::OAuth2::AccessToken.any_instance.should_not_receive(:refresh!)
        subject.access_token
      end
    end
  end

  describe "API method generation" do
    context "when the API hasn't been discovered" do
      it "should call out to the Discovery API" do
        GoogleAPI.discovered_apis[:drive].should be_nil
        subject.drive
        GoogleAPI.discovered_apis[:drive].should == fixture(:discovery_rest_drive)
      end

      it "should save the Discovery API map to the cache" do
        subject.drive
        GoogleAPI.discovered_apis[:drive].should == fixture(:discovery_rest_drive)
      end
    end

    context "when the API has already been discovered" do
      it "should not fetch the Discovery API map" do
        GoogleAPI.discovered_apis[:drive] = fixture(:discovery_drive)
        ::OAuth2::AccessToken.any_instance.should_not_receive(:get)
        subject.drive
      end
    end

    it "should build the GoogleAPI::API class" do
      GoogleAPI::API.should_receive(:new).with(an_instance_of(::OAuth2::AccessToken), :drive, fixture(:discovery_rest_drive)['resources'])
      subject.drive
    end
  end

end
