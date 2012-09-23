require 'spec_helper'

describe GoogleAPI::Client do

  let(:object) { User.new }
  let(:client) { GoogleAPI::Client.new(object) }
  before(:each) do
    GoogleAPI.configure do |config|
      config.client_id = 'test id'
      config.client_secret = 'test secret'
      config.encryption_key = 'encryption key'
    end
    object.authenticated = true
    client.client.connection = TEST_CONNECTION
  end

  describe "#initialize" do

    it "should set the object attribute" do
      client = GoogleAPI::Client.new(object)
      client.object.should == object
    end

    it "should raise NoMethodError if the object isn't oauthable" do
      expect {
        GoogleAPI::Client.new(Class.new)
      }.to raise_error(NoMethodError)
    end

    it "should raise ArgumentError if the object isn't OAuth2 authenticated" do
      object.authenticated = false
      expect {
        GoogleAPI::Client.new(object)
      }.to raise_error(ArgumentError)
    end

  end

  describe "#access_token" do

    it "should call to the OAuth2 Access Token class" do
      client.access_token.token.should == object.oauth_hash[:access_token]
    end

    context "when the access token is expired" do

      before(:each) { object.expires_at = Time.now - 86400 }

      it "should call refresh on the OAuth2 Access Token" do
        stubbed_access_token = Class.new
        stubbed_access_token.stub(:token).and_return('test token')
        ::OAuth2::AccessToken.any_instance.should_receive(:refresh!).and_return(stubbed_access_token)
        client.access_token
      end

      it "should update the object's stored OAuth information" do
        object.should_receive(:update_oauth!)
        client.access_token
      end

    end

    context "when the access token is fresh" do

      it "should not try and refresh the token again" do
        ::OAuth2::AccessToken.any_instance.should_not_receive(:refresh!)
        client.access_token
      end

    end

  end

  describe "#client" do

    it "should create the OAuth2 Client instance" do
      client.client.should be_an_instance_of(::OAuth2::Client)
    end

  end

  describe "API method generation" do

    context "when the API hasn't been discovered" do

      it "should call out to the Discovery API" do
        GoogleAPI.discovered_apis[:drive].should be_nil
        client.drive
        GoogleAPI.discovered_apis[:drive].should == fixture(:discovery_rest_drive)
      end

      it "should save the Discovery API map to the cache" do
        client.drive
        GoogleAPI.discovered_apis[:drive].should == fixture(:discovery_rest_drive)
      end

    end

    context "when the API has already been discovered" do

      it "should not fetch the Discovery API map" do
        GoogleAPI.discovered_apis[:drive] = fixture(:discovery_drive)
        ::OAuth2::AccessToken.any_instance.should_not_receive(:get)
        client.drive
      end

    end

    it "should build the GoogleAPI::API class" do
      GoogleAPI::API.should_receive(:new).with(an_instance_of(::OAuth2::AccessToken), :drive, fixture(:discovery_rest_drive)['resources'])
      client.drive
    end

  end

end
