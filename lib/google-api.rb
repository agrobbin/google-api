require 'google-api/oauth2'
require 'google-api/api'
require 'google-api/api/calendar'
require 'google-api/api/drive'
require 'google-api/api/drive/permission'
require 'google-api/client'
require 'google-api/railtie' if defined?(::Rails)

module GoogleAPI

  # This enables us to easily pass the client_id and client_secret with a
  # GoogleAPI.configure block. See the README for more information.
  # Loosely adapted from Twitter's configuration capabilities.
  # https://github.com/sferik/twitter/blob/v3.6.0/lib/twitter/configurable.rb
  class << self

    attr_accessor :client_id, :client_secret, :development_mode

    # Configuration options:
    #
    #   development_mode: make it easier to build your application with this API. Default is false
    def configure
      yield self

      raise ArgumentError, "GoogleAPI requires both a :client_id and :client_secret configuration option to be set." if client_id.blank? || client_secret.blank?

      @development_mode ||= false

      self
    end

  end

end
