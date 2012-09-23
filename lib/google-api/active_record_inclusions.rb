# Adapted from Paperclip's implementation of available migration methods
# https://github.com/thoughtbot/paperclip/blob/v3.1.4/lib/paperclip/schema.rb

module GoogleAPI
  module ActiveRecordInclusions

    def self.included(base)
      base.extend ClassMethods
      base.send :include, Migrations
    end

    module ClassMethods

      def oauthable
        define_method :oauth_hash do
          {
            access_token: GoogleAPI.decrypt!(oauth_access_token),
            refresh_token: GoogleAPI.decrypt!(oauth_refresh_token),
            expires_at: oauth_access_token_expires_at
          }
        end

        # This method is used both within the GoogleAPI and can be used outside it in your own app to update
        # the OAuth2 values in the database. Refresh token doesn't need to be passed, and any other attributes
        # that you want to update on the object can be passed as a final parameter.
        define_method :update_oauth! do |access_token, refresh_token = nil, additional_attrs = {}|
          attrs = {
            oauth_access_token: GoogleAPI.encrypt!(access_token),
            oauth_access_token_expires_at: 59.minutes.from_now # it's actually an hour from now, but just to make sure we don't overlap at all, let's set it to 59 minutes
          }.merge(additional_attrs)
          attrs[:refresh_token] = GoogleAPI.encrypt!(refresh_token) if refresh_token
          update_attributes(attrs)
        end

        define_method :google do
          GoogleAPI::Client.new(self)
        end
      end

    end

    module Migrations

      COLUMNS = {
        oauth_refresh_token: :string,
        oauth_access_token: :string,
        oauth_access_token_expires_at: :datetime
      }

      def self.included(base)
        ActiveRecord::ConnectionAdapters::Table.send :include, TableDefinition
        ActiveRecord::ConnectionAdapters::TableDefinition.send :include, TableDefinition
        ActiveRecord::ConnectionAdapters::AbstractAdapter.send :include, Statements
        ActiveRecord::Migration::CommandRecorder.send :include, CommandRecorder
      end

      module TableDefinition

        def oauthable
          COLUMNS.each do |name, type|
            column(name, type)
          end
        end

      end

      module Statements

        def add_oauthable
          COLUMNS.each do |name, type|
            add_column(name, type)
          end
        end

        def remove_oauthable
          COLUMNS.each do |name, type|
            remove_column(name, type)
          end
        end

      end

      module CommandRecorder

        def add_oauth
          record(:add_oauthable)
        end

        private
          def invert_add_oauth
            [:remove_oauthable]
          end

      end

    end

  end
end
