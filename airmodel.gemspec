lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

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

  spec.add_dependency 'airtable', '>= 0.0.9'
end
