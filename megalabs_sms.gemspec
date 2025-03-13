# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = 'megalabs_sms'
  spec.version       = MegalabsSms::VERSION
  spec.authors       = ['Vitalii Dementev']
  spec.email         = ['v@dementev.dev']
  spec.summary       = 'Ruby gem for sending SMS via the Megalabs API'
  spec.description   = 'This gem provides a simple interface to send SMS using the Megalabs A2P API.'
  spec.homepage      = 'https://dementevvv.github.io/megalabs_sms/'

  spec.metadata = {
    'homepage_uri' => 'https://dementevvv.github.io/megalabs_sms/',
    'documentation_uri' => 'https://dementevvv.github.io/megalabs_sms/',
    'source_code_uri' => 'https://github.com/DementevVV/megalabs_sms',
    'changelog_uri' => 'https://github.com/DementevVV/megalabs_sms/blob/master/CHANGELOG.md',
    'bug_tracker_uri' => 'https://github.com/DementevVV/megalabs_sms/issues',
    'rubygems_mfa_required' => 'true'
  }

  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 2.7.0'

  spec.files = Dir[
    'lib/**/*.rb',
    'spec/**/*.rb',
    'README.md',
    'LICENSE',
    'CHANGELOG.md',
    '.yardopts'
  ]
  spec.require_paths = ['lib']

  spec.add_dependency 'net-http', '~> 0.6.0'
  spec.add_dependency 'ostruct', '~> 0.6.0'

  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'webmock'
  spec.add_development_dependency 'yard'
end
