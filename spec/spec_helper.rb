# frozen_string_literal: true

require 'rspec'
require 'webmock/rspec'

require_relative '../lib/megalabs_sms'

RSpec.configure do |config|
  config.formatter = :documentation
  config.color     = true
end
