require 'google-api/oauth2'
require 'google-api/api'
require 'google-api/api/calendar'
require 'google-api/api/drive'
require 'google-api/api/drive/permission'
require 'google-api/client'
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

    attr_accessor :client_id, :client_secret, :development_mode, :logger

    # Configuration options:
    #
    #   development_mode: make it easier to build your application with this API. Default is false
    #   logger: if this gem is included in a Rails app, we will use the Rails.logger, otherwise, we log to STDOUT
    def configure
      yield self

      raise ArgumentError, "GoogleAPI requires both a :client_id and :client_secret configuration option to be set." if client_id.blank? || client_secret.blank?

      @development_mode ||= false
      @logger ||= defined?(::Rails) ? Rails.logger : stdout_logger

      self
    end

    def stdout_logger
      logger = Logger.new(STDOUT)
      logger.progname = "google-api"
      logger
    end

  end

end
