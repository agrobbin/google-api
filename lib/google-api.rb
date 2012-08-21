require 'google-api/api'
require 'google-api/api/calendar'
require 'google-api/api/drive'
require 'google-api/client'
require 'google-api/railtie'

module GoogleAPI

  # This enables us to easily pass the client_id and client_secret from the Rails
  # app with a GoogleAPI.configure block. See the README for more information.
  # Loosely adapted from Twitter's configuration capabilities.
  # https://github.com/sferik/twitter/blob/v3.6.0/lib/twitter/configurable.rb
  class << self

    attr_accessor :client_id, :client_secret

    def configure
      yield self
      self
    end

  end

end
