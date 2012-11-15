# -*- encoding: utf-8 -*-
Gem::Specification.new do |gem|
  gem.authors       = ["Alex Robbin"]
  gem.email         = ["alex@robbinsweb.biz"]
  gem.summary       = %q{A simple but powerful ruby API wrapper for Google's services.}
  gem.description   = gem.summary
  gem.homepage      = "https://github.com/agrobbin/google-api"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "google-api"
  gem.require_paths = ["lib"]
  gem.version       = "0.1.0"

  gem.add_runtime_dependency 'mime-types', '~> 1.0'
  gem.add_runtime_dependency 'oauth2', '~> 0.8.0'
  gem.add_development_dependency 'bundler'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'simplecov'
end
