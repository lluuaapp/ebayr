# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |gem|
  gem.authors       = ['JJ Buckley', 'Paul Hecker']
  gem.email         = ['jj@bjjb.org', 'paul@iwascoding.com.com']
  gem.summary       = 'A tidy library for using the eBay Trading API with Ruby'
  gem.description   = <<~DESCRIPTION
    eBayR is a gem that makes it (relatively) easy to use the eBay Trading API from
    Ruby. Includes a self-contained XML parser, a flexible callback system, and a
    command-line client which aids integration into other projects.
  DESCRIPTION
  gem.homepage      = 'http://github.com/bjjb/ebayr'
  gem.license       = 'MIT'
  gem.files         = [
    "Gemfile",
    "Guardfile",
    "LICENSE",
    "README.md",
    "Rakefile",
    "ebayr.gemspec",
    "lib/ebayr.rb",
    "lib/ebayr/record.rb",
    "lib/ebayr/request.rb",
    "lib/ebayr/response.rb",
    "lib/ebayr/configuration.rb"
  ]
  gem.executables   = []
  gem.name          = 'ebayr'
  gem.require_paths = ['lib']
  gem.version       = '0.4.2'

  gem.required_ruby_version = '>= 3.1'
  gem.add_dependency 'libxml-ruby', '>= 4', "< 6"
  gem.add_development_dependency 'rake', '>= 11', "< 15" # rubocop:disable Gemspec/DevelopmentDependencies
  gem.metadata['rubygems_mfa_required'] = 'true'
end
