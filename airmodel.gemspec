lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'airmodel/version'

Gem::Specification.new do |spec|
  spec.name          = 'airmodel'
  spec.version       = Airmodel::VERSION
  spec.authors       = ['chrisfrankdotfm']
  spec.email         = ['chris.frank@thefutureproject.org']
  spec.description   = 'Airtable data in ActiveRecord-style syntax'
  spec.summary       = 'Interact with your Airtable data using ActiveRecord-style models'
  spec.homepage      = 'https://github.com/chrisfrank/airmodel'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.test_files    = spec.files.grep('^(test|spec|features)/')
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1'
  spec.add_development_dependency 'rake', '~> 10'
  spec.add_development_dependency 'rspec', '~> 3'
  spec.add_development_dependency 'pry', '~> 0.10'
  spec.add_development_dependency 'fakeweb', '~> 1.3'

  spec.add_dependency 'airtable', '~> 0.0.8'
  spec.add_dependency 'activesupport', '~> 5.0'
end
