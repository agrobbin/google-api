stubs = Faraday::Adapter::Test::Stubs.new do |stub|
  stub.post('/o/oauth2/token') { faraday_response(:refresh_access_token) }
  stub.get('/discovery/v1/apis?name=drive&preferred=true') { faraday_response(:discovery_drive) }
  stub.get('/discovery/v1/apis/drive/v2/rest') { faraday_response(:discovery_rest_drive) }
  stub.post('/resumable/upload/drive/v2/files') { [200] }
  stub.get('/drive/v2/files') { faraday_response(:drive_files) }
  stub.delete('/drive/v2/files/adummyfileidnumber') { [204] }
  stub.put('/drive/v2/files/adummyfileidnumber') { faraday_response(:drive_error, 404) }
end

TEST_CONNECTION = Faraday.new do |builder|
  builder.adapter :test, stubs
end

def faraday_response(fixture, code = 200)
  [code, {'Content-Type' => 'application/json'}, fixture(fixture, false)]
end
