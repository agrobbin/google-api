**This gem is in its infancy! Proceed at your own risk...**

# Google API

[![Build Status](https://secure.travis-ci.org/agrobbin/google-api.png?branch=master)](https://travis-ci.org/agrobbin/google-api) [![Dependency Status](https://gemnasium.com/agrobbin/google-api.png)](https://gemnasium.com/agrobbin/google-api)

A simple but powerful ruby API wrapper for Google's services.

## Installation

Add this line to your application's Gemfile:

    gem 'google-api'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install google-api


## Before Using this Gem

Google API depends on you to authenticate each user with Google via OAuth2. We don't really care how you get authenticated, but you must request access to a User's Google account and save the Refresh Token, Access Token, and Access Token Expiration Date.

As a starting point, we recommend using Omniauth for most authentication with Ruby. It is a great gem, and integrates seemlessly with most SSO sites, including Google. Check out the [Wiki](https://github.com/agrobbin/google-api/wiki/Using-Omniauth-for-Authentication) for more information.

## Usage

This gem couldn't be easier to set up. Once you have a Client ID and Secret from Google (check out the [Wiki](https://github.com/agrobbin/google-api/wiki/Getting-a-Client-ID-and-Secret-from-Google) for instructions on how to get these), you just need to add an initializer to your application that looks like this:

```ruby
GoogleAPI.configure do |config|
  config.client_id = '[CLIENT ID]'
  config.client_secret = '[CLIENT SECRET]'
  config.encryption_key = '[ENCRYPTION KEY]'
end
```

We make it easy to set up an object as 'Google API Ready', giving you a couple of conveniences. For starters, if you have a User model, add the OAuth2 fields to your database migration:

```ruby
create_table :users do |t|
  t.string :email_address, :first_name, :last_name
  t.oauthable
  t.timestamps
end
```

...and methods to the Model:

```ruby
class User < ActiveRecord::Base

  oauthable

end
```

Once you have set that up, making a request to the Google API is as simple as:

```ruby
user = User.find(1)
user.google.drive.files.list
```

This will fetch all files and folders in the user's Google Drive and return them in an array of hashes.

## What Google APIs has this gem been tested against?

* Calendar
* Drive

## Help! I need to use an API that is not yet tested

Open an issue, and we will do our best to fully test the API you need. Or, you can submit a pull request with any necessary updates!

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
