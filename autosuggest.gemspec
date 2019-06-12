require_relative "lib/autosuggest/version"

Gem::Specification.new do |spec|
  spec.name          = "autosuggest"
  spec.version       = Autosuggest::VERSION
  spec.summary       = "Generate autocomplete suggestions based on what your users search"
  spec.homepage      = "https://github.com/ankane/autosuggest"
  spec.license       = "MIT"

  spec.author        = "Andrew Kane"
  spec.email         = "andrew@chartkick.com"

  spec.files         = Dir["*.{md,txt}", "{lib}/**/*"]
  spec.require_path  = "lib"

  spec.required_ruby_version = ">= 2.4"

  spec.add_dependency "ruby-stemmer"
  spec.add_dependency "obscenity"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"
end
