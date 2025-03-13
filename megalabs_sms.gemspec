# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = 'megalabs_sms'
  spec.version       = '0.1.0'
  spec.authors       = ['Vitalii Dementev']
  spec.email         = ['v@dementev.dev']
  spec.summary       = 'Ruby gem for sending SMS via the Megalabs API'
  spec.description   = 'This gem provides a simple interface to send SMS using the Megalabs A2P API.'
  spec.homepage      = 'https://github.com/DementevVV/megalabs_sms.git'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 2.7.0'

  spec.files         = Dir['lib/**/*.rb', 'spec/**/*.rb', 'README.md']
  spec.require_paths = ['lib']

  spec.add_dependency 'net-http', '~> 0.6.0'
  spec.add_dependency 'ostruct', '~> 0.6.0'

  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'webmock'
  spec.add_development_dependency 'yard'
end
