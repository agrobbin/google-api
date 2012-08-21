# Adapted from Paperclip's implementation of available migration methods
# https://github.com/thoughtbot/paperclip/blob/v3.1.4/lib/paperclip/railtie.rb

require 'google-api/active_record_inclusions'

module GoogleAPI
  class Railtie < Rails::Railtie

    initializer "google_api.configure_rails_initialization" do |app|
      ActiveRecord::Base.send(:include, ActiveRecordInclusions)
    end

  end
end
