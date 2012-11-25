## v0.3.0 (TBD)

* Save encrypted values as Base64-encoded strings. (NOTE: This is a non-backward compatible change!)

## v0.2.0 (2012-11-24)

* Rewrite token encryption to use OpenSSL's Cipher. (NOTE: This is a non-backward compatible change!)

## v0.1.0 (2012-11-14)

* Generalize #update_oauth! method for an oauthable ActiveRecord object. See active_record_inclusions.rb for more.

## v0.0.1.rc1 (2012-09-20)

* Add OAuth2 token encryption.

## v0.0.1.beta (2012-09-05)

* Full test suite for all classes and modules.
* Rethink and rebuild the API integration. Now discover the API and build methods dynamically! Works with the following Google APIs:
  * Calendar
  * Drive
* Add logger configuration.
* Add the #google method to an oauthable object.
* Add the #patch method to OAuth2.

## v0.0.1.alpha (2012-08-21)

* First release. (be careful!)
