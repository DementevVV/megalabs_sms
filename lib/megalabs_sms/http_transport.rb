# frozen_string_literal: true

require 'json'
require 'net/http'

module MegalabsSms
  #
  # Транспортный слой для выполнения HTTP-запросов и обработки ответов.
  #
  class HttpTransport
    def initialize(logger:, log_prefix:, open_timeout:, read_timeout:)
      @logger = logger
      @log_prefix = log_prefix
      @open_timeout = open_timeout
      @read_timeout = read_timeout
    end

    def send_request(uri, request)
      response = execute_http_request(uri, request)
      handle_http_response(response)
    rescue StandardError => e
      log(:error, "Exception occurred: #{e.class}: #{e.message}")
      false
    end

    private

    def execute_http_request(uri, request)
      Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
        http.open_timeout = @open_timeout
        http.read_timeout = @read_timeout
        http.request(request)
      end
    end

    def handle_http_response(response)
      return process_http_response(response.body) if response.is_a?(Net::HTTPSuccess)

      log(:warn, "Failed to send: HTTP #{response.code} #{response.message}")
      false
    end

    def process_http_response(raw_body)
      body = normalize_body(raw_body)
      success = response_success?(body)
      log(success ? :info : :warn, "#{success ? 'Successfully sent' : 'Failed to send'}: #{body}")
      success
    rescue JSON::ParserError => e
      log(:warn, "Failed to parse JSON: #{e.message}")
      false
    end

    def normalize_body(raw_body)
      raw_body.dup.force_encoding('UTF-8')
    end

    def response_success?(body)
      parsed = JSON.parse(body)
      result = parsed.dig('result', 'status')
      result&.fetch('code', nil)&.zero? && result&.fetch('description', '')&.downcase == 'ok'
    end

    def log(level, message)
      return unless @logger

      @logger.public_send(level, @log_prefix.call(message))
    end
  end
end
