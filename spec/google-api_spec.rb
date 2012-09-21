require 'spec_helper'

describe GoogleAPI do

  describe "#configure" do

    it "should raise an error when the CLIENT ID is blank" do
      expect {
        GoogleAPI.configure do |config|
          config.client_id = nil
          config.client_secret = 'test secret'
          config.encryption_key = 'encryption key'
        end
      }.to raise_error(ArgumentError)
    end

    it "should raise an error when the CLIENT SECRET is blank" do
      expect {
        GoogleAPI.configure do |config|
          config.client_id = 'test id'
          config.client_secret = nil
          config.encryption_key = 'encryption key'
        end
      }.to raise_error(ArgumentError)
    end

    it "should raise an error when the ENCRYPTION KEY is blank" do
      expect {
        GoogleAPI.configure do |config|
          config.client_id = 'test id'
          config.client_secret = 'test secret'
          config.encryption_key = nil
        end
      }.to raise_error(ArgumentError)
    end

    it "should raise an error when CLIENT ID, CLIENT SECRET, and ENCRYPTION KEY are blank" do
      expect {
        GoogleAPI.configure do |config|
          config.client_id = nil
          config.client_secret = nil
          config.encryption_key = nil
        end
      }.to raise_error(ArgumentError)
    end

    it "should set development mode to false when not passed" do
      GoogleAPI.configure do |config|
        config.client_id = 'test id'
        config.client_secret = 'test secret'
        config.encryption_key = 'encryption key'
      end

      GoogleAPI.development_mode.should be_false
    end

    it "should set development mode when passed" do
      GoogleAPI.configure do |config|
        config.client_id = 'test id'
        config.client_secret = 'test secret'
        config.encryption_key = 'encryption key'
        config.development_mode = true
      end

      GoogleAPI.development_mode.should be_true
    end

    it "should use Rails' logger when Rails is defined" do
      stub_const("Rails", Class.new)
      Rails.stub(:logger).and_return(Logger.new(STDOUT))

      Rails.should_receive(:logger)

      GoogleAPI.configure do |config|
        config.client_id = 'test id'
        config.client_secret = 'test secret'
        config.encryption_key = 'encryption key'
      end

    end

    it "should use a STDOUT when Rails is not defined" do
      GoogleAPI.should_receive(:stdout_logger)

      GoogleAPI.configure do |config|
        config.client_id = 'test id'
        config.client_secret = 'test secret'
        config.encryption_key = 'encryption key'
      end
    end

  end

  describe "#discovered_apis" do

    it "should start as an empty hash" do
      GoogleAPI.discovered_apis.should == {}
    end

    it "should keep a cache of discovered APIs" do
      GoogleAPI.discovered_apis[:test_api1] = {a: 1, b: 2, c: 3}

      GoogleAPI.discovered_apis[:test_api1].should == {a: 1, b: 2, c: 3}
    end

  end

  describe "#stdout_logger" do

    let(:logger) { GoogleAPI.stdout_logger }

    it "should create a new Logger object" do
      logger = GoogleAPI.stdout_logger
      logger.should be_an_instance_of(Logger)
    end

  end

  describe "#encrypt!" do

    it "should return an encrypted version of the string" do
      GoogleAPI.configure do |config|
        config.client_id = 'test id'
        config.client_secret = 'test secret'
        config.encryption_key = 'encryption key'
      end

      GoogleAPI.encrypt!('test').should == "dGVzdGVuY3J5cHRpb24ga2V5\n"
    end

  end

  describe "#decrypt!" do

    it "should return an decrypted version of the string" do
      GoogleAPI.configure do |config|
        config.client_id = 'test id'
        config.client_secret = 'test secret'
        config.encryption_key = 'encryption key'
      end

      GoogleAPI.decrypt!("dGVzdGVuY3J5cHRpb24ga2V5\n").should == 'test'
    end

  end

end
