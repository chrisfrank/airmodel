lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'airmodel/version'

Gem::Specification.new do |spec|
  spec.name          = 'airmodel'
  spec.version       = Airmodel::VERSION
  spec.authors       = ['chrisfrankdotfm']
  spec.email         = ['chris.frank@thefutureproject.org']
  spec.description   = 'Builds AR-style models on top of airtable-ruby.'
  spec.summary       = 'Builds AR-style models on top of airtable-ruby.'
  spec.homepage      = 'https://github.com/chrisfrank/airmodel'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.test_files    = spec.files.grep('^(test|spec|features)/')
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'fakeweb'

  spec.add_dependency 'airtable', '~> 0.0.8'
  spec.add_dependency 'activesupport', '~> 5.0.0'
end
