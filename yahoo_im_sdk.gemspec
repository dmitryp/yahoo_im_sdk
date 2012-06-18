# -*- encoding: utf-8 -*-
require File.expand_path('../lib/yahoo_im_sdk/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Dmitry Penkin"]
  gem.email         = ["dr.demax@gmail.com"]
  gem.description   = %q{A Ruby SDK and example for using the Yahoo! Messenger API (http://developer.yahoo.com/messenger/)}
  gem.summary       = %q{TODO: Write a gem summary}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "yahoo_im_sdk"
  gem.require_paths = ["lib"]
  gem.version       = YahooImSdk::VERSION

  gem.add_dependency "httparty"
  gem.add_dependency "crack"
  gem.add_development_dependency "rspec", "~> 2.6"
  gem.add_development_dependency "fakeweb"
end
