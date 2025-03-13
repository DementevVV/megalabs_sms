# frozen_string_literal: true

require 'net/http'
require 'json'
require_relative 'megalabs_sms/version'

#
# Главный модуль для взаимодействия с API Megalabs, включая отправку SMS.
#
module MegalabsSms
  # Класс для взаимодействия с API Megalabs для отправки SMS
  class Client
    #
    # Конструктор, инициализирующий параметры клиента:
    #
    # @param api_user [String] логин для Basic Auth
    # @param api_password [String] пароль для Basic Auth
    # @param sleep_time [Float] время задержки в секундах (по умолчанию 0)
    # @param success_stub [Boolean] эмулировать успешную отправку?
    # @param error_stub [Boolean] эмулировать ошибку отправки?
    #
    # @raise [ArgumentError] если api_user или api_password отсутствуют или пусты
    #
    def initialize(api_user,
                   api_password,
                   sleep_time: 0,
                   success_stub: false,
                   error_stub: false)
      raise ArgumentError, 'api_user is required' if api_user.nil? || api_user.strip.empty?
      raise ArgumentError, 'api_password is required' if api_password.nil? || api_password.strip.empty?

      @api_user = api_user
      @api_password = api_password
      @sleep_time = sleep_time
      @success_stub = success_stub
      @error_stub = error_stub
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
    #
    # @return [String] статус отправки или текст ошибки
    #
    def send_sms(from, to, message)
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
    # @return [String] сообщение об успехе или ошибке эмуляции
    #
    def handle_stub_response
      return log_message('Stubbed error: SMS not sent') if @error_stub

      log_message('Stubbed success: SMS would be sent') if @success_stub
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
      uri = URI('https://a2p-api.megalabs.ru/sms/v1/sms')
      request = Net::HTTP::Post.new(uri)
      request.basic_auth(@api_user, @api_password)
      request.content_type = 'application/json'
      request.body = build_request_body(from, to, message)
      request
    end

    #
    # Создает HTTP-запрос для отправки SMS
    #
    # @param from [String] имя/номер отправителя
    # @param to [String] <description>
    # @param message [String] <description>
    #
    # @return [Net::HTTP::Post] объект HTTP-запроса
    #
    def build_request_body(from, to, message)
      {
        from: from,
        to: to.gsub(/\D/, '').to_i,
        message: message
      }.to_json
    end

    #
    # Отправляет HTTP-запрос
    #
    # @param request [Net::HTTP::Post] объект HTTP-запроса
    #
    # @return [String] тело ответа или сообщение об ошибке
    #
    def send_request(request)
      uri = URI('https://a2p-api.megalabs.ru/sms/v1/sms')
      response_body = perform_http_request(uri, request)
      sleep(@sleep_time) if @sleep_time.positive?
      response_body
    end

    #
    # Выполняет HTTP-запрос
    #
    # @param uri [URI] URI-адрес для запроса
    # @param request [Net::HTTP::Post] объект HTTP-запроса
    #
    # @return [String] тело ответа или сообщение об ошибке
    #
    def perform_http_request(uri, request)
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
        http.request(request)
      end

      if response.is_a?(Net::HTTPSuccess)
        process_http_response(response.body)
      else
        log_message("Failed to send: #{response}")
      end
    rescue StandardError => e
      log_message("Exception occurred: #{e.message}")
    end

    #
    # Обрабатывает тело ответа HTTP и возвращает корректное сообщение.
    # Если статус ответа не соответствует ожидаемому, возвращает сообщение об ошибке.
    #
    # @param raw_body [String] оригинальный ответ от HTTP-запроса
    #
    # @return [String] либо оригинальное тело (если все хорошо), либо сообщение об ошибке
    #
    def process_http_response(raw_body)
      body = raw_body.dup.force_encoding('UTF-8')
      parsed = JSON.parse(body)
      result = parsed.dig('result', 'status')
      return body if result&.fetch('code', nil)&.zero? && result&.fetch('description', '')&.downcase == 'ok'

      log_message("Failed to send: #{body}")
    rescue JSON::ParserError => e
      log_message("Failed to parse JSON: #{e.message}")
    end
  end
end
