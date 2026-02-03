# frozen_string_literal: true

module MegalabsSms
  #
  # Вспомогательный модуль для нормализации и валидации настроек клиента.
  #
  module ClientConfig
    DEFAULTS = {
      sleep_time: 0,
      success_stub: false,
      error_stub: false,
      logger: nil,
      open_timeout: 5,
      read_timeout: 10
    }.freeze

    def self.normalize(options)
      DEFAULTS.merge(options)
    end

    def self.validate_credentials!(api_user, api_password)
      raise ArgumentError, 'api_user is required' if api_user.nil? || api_user.strip.empty?
      raise ArgumentError, 'api_password is required' if api_password.nil? || api_password.strip.empty?
    end

    def self.validate_timeouts!(options)
      raise ArgumentError, 'sleep_time must be >= 0' if options[:sleep_time].to_f.negative?
      raise ArgumentError, 'open_timeout must be > 0' if options[:open_timeout].to_f <= 0
      raise ArgumentError, 'read_timeout must be > 0' if options[:read_timeout].to_f <= 0
    end

    def self.apply!(client, api_user, api_password, options)
      client.instance_variable_set(:@api_user, api_user)
      client.instance_variable_set(:@api_password, api_password)
      client.instance_variable_set(:@sleep_time, options[:sleep_time])
      client.instance_variable_set(:@success_stub, options[:success_stub])
      client.instance_variable_set(:@error_stub, options[:error_stub])
      client.instance_variable_set(:@logger, options[:logger])
      client.instance_variable_set(:@open_timeout, options[:open_timeout])
      client.instance_variable_set(:@read_timeout, options[:read_timeout])
      client.instance_variable_set(:@http_transport, nil)
    end
  end
end
