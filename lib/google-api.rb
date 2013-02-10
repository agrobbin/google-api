require 'mime/types'
require 'oauth2'
require 'google-api/api'
require 'google-api/client'
require 'google-api/encrypter'
if defined?(::Rails)
  require 'google-api/railtie'
else
  require 'logger'
end

module GoogleAPI

  # This enables us to easily pass the client_id and client_secret with a
  # GoogleAPI.configure block. See the README for more information.
  # Loosely adapted from Twitter's configuration capabilities.
  # https://github.com/sferik/twitter/blob/v3.6.0/lib/twitter/configurable.rb
  class << self

    attr_accessor :client_id, :client_secret, :encryption_key, :development_mode, :logger

    # Configuration options:
    #
    #   development_mode: make it easier to build your application with this API. Default is false
    #   logger: if this gem is included in a Rails app, we will use the Rails.logger, otherwise, we log to STDOUT
    def configure
      yield self

      raise ArgumentError, "GoogleAPI requires both a :client_id and :client_secret configuration option to be set." unless [client_id, client_secret, encryption_key].all?

      @development_mode ||= false
      @logger ||= defined?(::Rails) ? Rails.logger : stdout_logger

      self
    end

    # An internally used hash to cache the discovered API responses.
    # Keys could be 'drive', 'calendar', 'contacts', etc.
    # Values will be a parsed JSON hash.
    def discovered_apis
      @discovered_apis ||= {}
    end

    # The default logger for this API. When we aren't within a Rails app,
    # we will output log messages to STDOUT.
    def stdout_logger
      logger = Logger.new(STDOUT)
      logger.progname = "google-api"
      logger
    end

    # Used primarily within the test suite to reset our GoogleAPI environment for each test.
    def reset_environment!
      @development_mode = false
      @logger = nil
      @discovered_apis = {}
    end

  end

end
