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

        define_method :update_access_token! do |access_token|
          self.oauth_access_token = GoogleAPI.encrypt!(access_token)
          self.oauth_access_token_expires_at = 59.minutes.from_now
          self.save
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
