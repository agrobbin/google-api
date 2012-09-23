module GoogleAPI
  class Client

    attr_reader :object

    # This is where the magic happens. All methods are based off of a new Client object.
    # Before we go anywhere else, however, we must make sure that the object passed to the
    # #new method is oauthable. If not, raise an error telling the user.
    def initialize(object)
      @object = object

      raise NoMethodError, "#{self.class} must be passed an object that is to oauthable. #{object.class.name} is not oauthable." unless object.class.respond_to?(:oauthable)
      raise ArgumentError, "#{object.class.name} does not appeared to be OAuth2 authenticated. GoogleAPI requires :oauth_access_token, :oauth_request_token, and :oauth_access_token_expires_at to be present." unless object.oauth_hash.values.all?
    end

    # Build an AccessToken object from OAuth2. Check if the access token is expired, and if so,
    # refresh it and save the new access token returned from Google.
    def access_token
      @access_token = ::OAuth2::AccessToken.new(client, object.oauth_hash[:access_token],
        refresh_token: object.oauth_hash[:refresh_token],
        expires_at: object.oauth_hash[:expires_at].to_i
      )
      if @access_token.expired?
        GoogleAPI.logger.info "Access Token expired for #{object.class.name}(#{object.id}), refreshing..."
        @access_token = @access_token.refresh!
        object.update_oauth!(@access_token.token)
      end

      @access_token
    end

    # Build the OAuth2::Client object to be used when building an AccessToken.
    def client
      @client ||= ::OAuth2::Client.new(GoogleAPI.client_id, GoogleAPI.client_secret,
        site: 'https://accounts.google.com',
        token_url: '/o/oauth2/token',
        raise_errors: false
      )
    end

    # We build the appropriate API here based on the method name passed to the Client.
    # For example:
    #
    #   User.find(1).google.drive
    #
    # We will then discover and cache the Google Drive API for future use.
    # Any methods chained to the resultant API will then be passed along to the
    # instantiaed class. Read the documentation for GoogleAPI::API#method_missing for
    # more information.
    def method_missing(api, *args)
      unless GoogleAPI.discovered_apis.has_key?(api)
        GoogleAPI.logger.info "Discovering the #{api} Google API..."
        response = access_token.get("https://www.googleapis.com/discovery/v1/apis?preferred=true&name=#{api}").parsed['items']
        super unless response # Raise a NoMethodError if Google's Discovery API does not return a good response
        discovery_url = response.first['discoveryRestUrl']
        GoogleAPI.discovered_apis[api] = access_token.get(discovery_url).parsed
      end

      API.new(access_token, api, GoogleAPI.discovered_apis[api]['resources'])
    end

  end
end