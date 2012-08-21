module GoogleAPI
  class Client

    attr_reader :object

    # This is where the magic happens. All methods are based off of a new Client object.
    # Before we go anywhere else, however, we must make sure that the object passed to the
    # #new method is oauthable. If not, raise an error telling the user.
    def initialize(object)
      @object = object

      raise NoMethodError, "GoogleAPI::Client must be passed an object that is to oauthable. #{object.class.name} is not oauthable." unless object.class.respond_to?(:oauthable)
    end

    # Build an AccessToken object from OAuth2. Check if the access token is expired, and if so,
    # refresh it and save the new access token returned from Google.
    def access_token
      @access_token ||= ::OAuth2::AccessToken.new(client, oauth_hash[:access_token], oauth_hash.except(:access_token))
      if @access_token.expired?
        puts "Access Token expired, refreshing..."
        @access_token = @access_token.refresh!
        object.update_access_token!(@access_token.token)
      end

      @access_token
    end

    # Build the oauth_hash used to build the AccessToken object above. If any of the values
    # are nil?, we raise an error and tell the user.
    def oauth_hash
      unless @oauth_hash
        hash = object.oauth_hash.dup
        hash[:expires_at] = hash[:expires_at].to_i if hash[:expires_at].present?
        raise ArgumentError, "#{object.class.name} does not appeared to be OAuth2 authenticated. GoogleAPI requires :oauth_access_token, :oauth_request_token, and :oauth_access_token_expires_at to be present." unless hash.values.all?
      end

      @oauth_hash ||= hash
    end

    # Build the OAuth2::Client object to be used when building an AccessToken.
    def client
      puts "Creating the OAuth2::Client object..." unless @client
      @client ||= ::OAuth2::Client.new(GoogleAPI.client_id, GoogleAPI.client_secret,
        site: 'https://accounts.google.com',
        token_url: '/o/oauth2/token',
        raise_errors: false
      )
    end

    # Each API that Google offers us is instantiated within its own method below.
    # If you want to find all calendars for a user, you would do this:
    #
    #   GoogleAPI::Client.new(User.first).calendar.all
    #
    # See GoogleAPI::Calendar for more information about the Calendar API.
    %w(calendar drive).each do |api|
      define_method api do
        "GoogleAPI::#{api.capitalize}".constantize.new(access_token)
      end
    end

  end
end