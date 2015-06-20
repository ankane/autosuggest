# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "autosuggest/version"

Gem::Specification.new do |spec|
  spec.name          = "autosuggest"
  spec.version       = Autosuggest::VERSION
  spec.authors       = ["Andrew Kane"]
  spec.email         = ["andrew@chartkick.com"]

  spec.summary       = "Generate autocomplete suggestions based on what your users search"
  spec.homepage      = "https://github.com/ankane/autosuggest"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "ruby-stemmer"
  spec.add_dependency "obscenity"

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest"
end
