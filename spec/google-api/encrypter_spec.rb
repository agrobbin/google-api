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
      GoogleAPI::Encrypter.encrypt!('test').should == "MMLzeQigMLGcvTvHczYxjg=="
    end

  end

  describe "#decrypt!" do

    it "should return an decrypted version of the string" do
      GoogleAPI::Encrypter.decrypt!("MMLzeQigMLGcvTvHczYxjg==").should == 'test'
    end

  end

end
