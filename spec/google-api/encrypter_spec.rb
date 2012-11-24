require 'spec_helper'

describe GoogleAPI::Encrypter do

  before(:each) do
    GoogleAPI.configure do |config|
      config.client_id = 'test id'
      config.client_secret = 'test secret'
      config.encryption_key = 'a really really really really really really long encryption key'
    end
  end

  describe "#encrypt!" do

    it "should return an encrypted version of the string" do
      GoogleAPI::Encrypter.encrypt!('test').should == "0\xC2\xF3y\b\xA00\xB1\x9C\xBD;\xC7s61\x8E"
    end

  end

  describe "#decrypt!" do

    it "should return an decrypted version of the string" do
      GoogleAPI::Encrypter.decrypt!("0\xC2\xF3y\b\xA00\xB1\x9C\xBD;\xC7s61\x8E").should == 'test'
    end

  end

end
