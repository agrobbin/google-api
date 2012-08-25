require 'simplecov'
SimpleCov.start do
  add_filter 'spec'
end

require 'rspec'
require 'google-api'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}
