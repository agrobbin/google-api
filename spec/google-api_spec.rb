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
    subject { GoogleAPI.discovered_apis }

    it { should be_an_instance_of(Hash) }
    it { should be_empty }

    context "when a new api is cached" do
      before { GoogleAPI.discovered_apis[:test_api1] = {a: 1, b: 2, c: 3} }

      its([:test_api1]) { should == {a: 1, b: 2, c: 3} }
    end
  end

  describe "#stdout_logger" do
    subject { GoogleAPI.stdout_logger }

    it { should be_an_instance_of(Logger) }
  end

end
