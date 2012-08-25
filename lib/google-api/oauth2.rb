# This can go away once the below commit is released with OAuth2.
# https://github.com/intridea/oauth2/commit/8dc6feab9927c3fc03b8e0975909a96049a1cbd3
# Should be in 0.8.1 or 0.9.0

module OAuth2
  class AccessToken

    # Make a PATCH request with the Access Token
    #
    # @see AccessToken#request
    def patch(path, opts={}, &block)
      request(:patch, path, opts, &block)
    end

  end
end
