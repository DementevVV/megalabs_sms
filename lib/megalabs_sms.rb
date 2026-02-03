# frozen_string_literal: true

require 'json'
require 'logger'
require 'net/http'
require_relative 'megalabs_sms/version'
require_relative 'megalabs_sms/http_transport'
require_relative 'megalabs_sms/client_config'

#
# Главный модуль для взаимодействия с API Megalabs, включая отправку SMS.
#
module MegalabsSms
  # Класс для взаимодействия с API Megalabs для отправки SMS
  class Client
    DEFAULT_ENDPOINT = URI('https://a2p-api.megalabs.ru/sms/v1/sms')
    DEFAULT_OPEN_TIMEOUT = ClientConfig::DEFAULTS[:open_timeout]
    DEFAULT_READ_TIMEOUT = ClientConfig::DEFAULTS[:read_timeout]

    #
    # Конструктор, инициализирующий параметры клиента:
    #
    # @param api_user [String] логин для Basic Auth
    # @param api_password [String] пароль для Basic Auth
    # @param options [Hash] доп. настройки клиента
    # @option options [Float] :sleep_time время задержки в секундах (по умолчанию 0)
    # @option options [Boolean] :success_stub эмулировать успешную отправку?
    # @option options [Boolean] :error_stub эмулировать ошибку отправки?
    # @option options [Logger, nil] :logger логгер для вывода сообщений (по умолчанию nil)
    # @option options [Numeric] :open_timeout таймаут на открытие соединения
    # @option options [Numeric] :read_timeout таймаут на чтение ответа
    #
    # @raise [ArgumentError] если api_user или api_password отсутствуют или пусты
    #
    def initialize(api_user, api_password, **options)
      ClientConfig.validate_credentials!(api_user, api_password)
      options = ClientConfig.normalize(options)
      ClientConfig.validate_timeouts!(options)
      ClientConfig.apply!(self, api_user, api_password, options)
    end

    #
    # Метод для форматирования сообщений логирования
    #
    # @param message [String] исходное сообщение для логирования
    #
    # @return [String] отформатированное сообщение с префиксом модуля
    #
    def log_message(message)
      "[MegalabsSms] #{message}"
    end

    #
    # Метод для отправки SMS через сервис Megalabs.
    #
    # @param from [String] имя/номер отправителя
    # @param to [String] номер телефона получателя
    # @param message [String] текст сообщения
    # @param kwargs [Hash] альтернативные именованные аргументы
    #
    # @return [Boolean] true если SMS отправлено успешно, false в случае ошибки
    #
    def send_sms(from = nil, to = nil, message = nil, **kwargs)
      if kwargs.any?
        raise ArgumentError, 'use either keyword arguments or positional arguments, not both' if from || to || message

        from = kwargs.fetch(:from)
        to = kwargs.fetch(:to)
        message = kwargs.fetch(:message)
      end

      validate_message_args!(from, to, message)
      return handle_stub_response if stub_enabled?

      request = build_request(from, to, message)
      send_request(request)
    end

    private

    #
    # Проверяет, включен ли режим эмуляции ответов
    #
    # @return [Boolean] true если включена эмуляция успеха или ошибки, false в противном случае
    #
    def stub_enabled?
      @error_stub || @success_stub
    end

    #
    # Обрабатывает эмуляцию ответов
    #
    # @return [Boolean] true если эмулируется успех, false если эмулируется ошибка
    #
    def handle_stub_response
      if @error_stub
        log(:warn, 'Stubbed error: SMS not sent')
        false
      elsif @success_stub
        log(:info, 'Stubbed success: SMS would be sent')
        true
      end
    end

    #
    # Создает HTTP-запрос для отправки SMS
    #
    # @param from [String] имя отправителя
    # @param to [String] номер телефона получателя
    # @param message [String] текст сообщения
    #
    # @return [Net::HTTP::Post] объект HTTP-запроса
    #
    def build_request(from, to, message)
      request = Net::HTTP::Post.new(DEFAULT_ENDPOINT)
      request.basic_auth(@api_user, @api_password)
      request.content_type = 'application/json'
      request.body = build_request_body(from, to, message)
      request
    end

    #
    # Создает тело HTTP-запроса для отправки SMS
    #
    # @param from [String] имя/номер отправителя
    # @param to [String] номер телефона получателя
    # @param message [String] текст сообщения
    #
    # @return [String] JSON-тело запроса
    #
    def build_request_body(from, to, message)
      digits = to.to_s.gsub(/\D/, '')
      raise ArgumentError, 'to must contain digits' if digits.empty?

      {
        from: from,
        to: digits.to_i,
        message: message
      }.to_json
    end

    #
    # Отправляет HTTP-запрос
    #
    # @param request [Net::HTTP::Post] объект HTTP-запроса
    #
    # @return [Boolean] true если запрос выполнен успешно, false в случае ошибки
    #
    def send_request(request)
      success = http_transport.send_request(DEFAULT_ENDPOINT, request)
      sleep(@sleep_time) if @sleep_time.positive?
      success
    end

    #
    # Проверяет входные параметры отправки
    #
    # @param from [String] имя/номер отправителя
    # @param to [String] номер телефона получателя
    # @param message [String] текст сообщения
    #
    # @raise [ArgumentError] если параметры отсутствуют или пусты
    #
    def validate_message_args!(from, to, message)
      raise ArgumentError, 'from is required' if from.nil? || from.to_s.strip.empty?
      raise ArgumentError, 'to is required' if to.nil? || to.to_s.strip.empty?
      raise ArgumentError, 'message is required' if message.nil? || message.to_s.strip.empty?
    end

    #
    # Логирует сообщение, если задан логгер
    #
    # @param level [Symbol] уровень логирования
    # @param message [String] сообщение
    #
    def log(level, message)
      return unless @logger

      @logger.public_send(level, log_message(message))
    end

    #
    # Возвращает транспорт для HTTP-запросов
    #
    # @return [MegalabsSms::HttpTransport]
    #
    def http_transport
      @http_transport ||= HttpTransport.new(
        logger: @logger,
        log_prefix: method(:log_message),
        open_timeout: @open_timeout,
        read_timeout: @read_timeout
      )
    end
  end
end
