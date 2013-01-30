require 'spec_helper'

shared_context "api call" do
  let(:map) { fixture(:discovery_rest_drive)['resources']['files']['methods'] }
  let(:api) { GoogleAPI::API.new(client.access_token, :drive, map) }
  let(:stubbed_response) { OAuth2Response.new }

  before do
    GoogleAPI.discovered_apis[:drive] = fixture(:discovery_rest_drive)
    client.client.connection = TEST_CONNECTION
  end
end

describe GoogleAPI::API do

  let(:object) { User.new }
  let(:client) { GoogleAPI::Client.new(object) }

  before do
    GoogleAPI.configure do |config|
      config.client_id = 'test id'
      config.client_secret = 'test secret'
      config.encryption_key = 'encryption key'
    end
    GoogleAPI.logger.stub(:error)
    object.authenticated = true
  end

  describe "#initialize" do
    subject { GoogleAPI::API.new(client.access_token, :drive, fixture(:discovery_rest_drive)['resources']) }

    its(:api) { should == :drive }
    its(:map) { should == fixture(:discovery_rest_drive)['resources'] }
    its('access_token.token') { should == client.access_token.token }
  end

  describe "API method generation" do
    context "when there are methods lower in the tree" do
      it "should build another GoogleAPI::API class with the correct map" do
        api = GoogleAPI::API.new(client.access_token, :drive, fixture(:discovery_rest_drive)['resources'])
        api.files.should be_an_instance_of(GoogleAPI::API)
      end
    end

    context "when the method tree is the lowest it can be" do
      include_context "api call"

      it "should call the #build_url method" do
        api.should_receive(:build_url).with(map['list'], {}).and_return(['https://www.googleapis.com/drive/v2/files', {}])
        api.list
      end

      %w(POST PUT PATCH).each do |http_method|
        context "when the method's HTTP method is #{http_method}" do
          it "should raise ArgumentError if no body was passed" do
            expect { api.insert(media: '/Test/File/Path.txt') }.to raise_error(ArgumentError)
          end
        end
      end

      context "when the mediaUpload key is present" do
        it "should call the #upload method" do
          api.should_receive(:upload).with('post', 'https://www.googleapis.com/resumable/upload/drive/v2/files', body: {title: 'Test File.txt'}, media: '/Test/File/Path.txt')
          api.insert(body: {title: 'Test File.txt'}, media: '/Test/File/Path.txt')
        end
      end

      context "when it is a normal API method request" do
        it "should delegate to the #request method" do
          api.should_receive(:request).with('get', 'https://www.googleapis.com/drive/v2/files', {})
          api.list
        end
      end
    end
  end

  describe "#request" do
    include_context "api call"

    it "should build the correct headers hash" do
      ::OAuth2::AccessToken.any_instance.should_receive(:get).with('https://www.googleapis.com/drive/v2/files', headers: {'Content-Type' => 'application/json'}).and_return(stubbed_response)
      api.list
    end

    it "should convert the body to JSON" do
      ::OAuth2::AccessToken.any_instance.should_receive(:post).with('https://www.googleapis.com/drive/v2/files', body: '{"title":"Test Folder"}', headers: {'Content-Type' => 'application/json'}).and_return(stubbed_response)
      api.insert(body: {title: 'Test Folder'})
    end

    context "when a request is successful" do
      it "should only make the request attempt once" do
        ::OAuth2::AccessToken.any_instance.should_receive(:get).once.and_return(stubbed_response)
        api.list
      end

      it "should return a parsed response if body is present" do
        api.list.should == fixture(:drive_files)
      end

      it "should return the full Response object if body is blank" do
        api.delete(fileId: 'adummyfileidnumber').should be_an_instance_of(::OAuth2::Response)
      end
    end

    context "when a request fails and development mode is turned off" do
      it "should attempt the request 5 times" do
        ::OAuth2::AccessToken.any_instance.should_receive(:put).exactly(5).times.and_return(OAuth2Response.new(404))
        api.update(fileId: 'adummyfileidnumber', body: {bad: 'attribute'})
      end

      it "should break out of the attempt loop if the request succeeds" do
        ::OAuth2::AccessToken.any_instance.should_receive(:put).exactly(2).times.and_return(OAuth2Response.new(404))
        ::OAuth2::AccessToken.any_instance.should_receive(:put).once.and_return(stubbed_response)
        api.update(fileId: 'adummyfileidnumber', body: {bad: 'attribute'})
      end
    end
  end

  describe "#upload" do
    include_context "api call"

    before { api.stub(:request).and_return(stubbed_response) }

    it "should build the correct options hash that is passed to the first request" do
      api.should_receive(:request).with('post', 'https://www.googleapis.com/resumable/upload/drive/v2/files', body: {title: 'Test File.txt', mimeType: 'application/x-ruby'}, headers: {'X-Upload-Content-Type' => 'application/x-ruby'})
      api.send(:upload, 'post', 'https://www.googleapis.com/resumable/upload/drive/v2/files', body: {title: 'Test File.txt'}, media: File.expand_path('spec/spec_helper.rb'))
    end

    it "should change the original headers for the actual file upload" do
      api.should_receive(:request)
      api.should_receive(:request).with(:put, nil, body: File.read(File.expand_path('spec/spec_helper.rb')), headers: {'Content-Type' => 'application/x-ruby', 'Content-Length' => '392'})
      api.send(:upload, 'post', 'https://www.googleapis.com/resumable/upload/drive/v2/files', body: {title: 'Test File.txt'}, media: File.expand_path('spec/spec_helper.rb'))
    end
  end

  describe "#build_url" do
    include_context "api call"

    context "when the mediaUpload key is present" do
      it "should use the rootUrl of the discovered API" do
        url, options = api.send(:build_url, map['insert'], media: File.expand_path('spec/spec_helper.rb'))
        url.should == 'https://www.googleapis.com/resumable/upload/drive/v2/files'
      end
    end

    context "when it is a normal API method request" do
      it "should build the final URL" do
        url, options = api.send(:build_url, map['get'], fileId: 'adummyfileidnumber', updateViewedDate: true)
        url.should == 'https://www.googleapis.com/drive/v2/files/adummyfileidnumber?updateViewedDate=true'
      end

      it "should delete query/path parameters from the options Hash" do
        url, options = api.send(:build_url, map['get'], fileId: 'adummyfileidnumber', updateViewedDate: true)
        options.should == {}
      end

      it "should raise ArgumentError if the parameter is required and the matching option isn't passed" do
        expect { api.send(:build_url, map['get'], updateViewedDate: true) }.to raise_error(ArgumentError)
      end
    end
  end

end
