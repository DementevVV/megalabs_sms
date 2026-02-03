# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable Metrics/BlockLength

RSpec.describe MegalabsSms::Client do
  let(:api_user)     { 'test_user' }
  let(:api_password) { 'test_password' }
  let(:sleep_time)   { 0 }
  let(:from)         { 'TestSender' }
  let(:to)           { '+70001234567' }
  let(:message)      { 'Hello from RSpec!' }
  let(:logger)       { instance_double(Logger, info: true, warn: true, error: true) }

  subject(:client) do
    described_class.new(
      api_user,
      api_password,
      sleep_time: sleep_time,
      success_stub: success_stub,
      error_stub: error_stub,
      logger: logger
    )
  end

  describe 'validation' do
    let(:success_stub) { false }
    let(:error_stub)   { false }

    it 'raises an error when api_user is missing' do
      expect do
        described_class.new(nil, api_password, logger: logger)
      end.to raise_error(ArgumentError, 'api_user is required')
    end

    it 'raises an error when api_password is missing' do
      expect do
        described_class.new(api_user, ' ', logger: logger)
      end.to raise_error(ArgumentError, 'api_password is required')
    end

    it 'raises an error when sleep_time is negative' do
      expect do
        described_class.new(api_user, api_password, sleep_time: -1, logger: logger)
      end.to raise_error(ArgumentError, 'sleep_time must be >= 0')
    end

    it 'raises an error when message is blank' do
      expect do
        client.send_sms(from, to, ' ')
      end.to raise_error(ArgumentError, 'message is required')
    end

    it 'raises an error when to has no digits' do
      expect do
        client.send_sms(from, 'abc', message)
      end.to raise_error(ArgumentError, 'to must contain digits')
    end
  end

  context 'with stub responses' do
    context 'when success_stub is true' do
      let(:success_stub) { true }
      let(:error_stub)   { false }

      it 'returns true indicating success' do
        allow(logger).to receive(:info).and_return(true)
        result = client.send_sms(from, to, message)
        expect(result).to eq(true)
        expect(logger).to have_received(:info).with('[MegalabsSms] Stubbed success: SMS would be sent')
      end
    end

    context 'when error_stub is true' do
      let(:success_stub) { false }
      let(:error_stub)   { true }

      it 'returns false indicating failure' do
        allow(logger).to receive(:warn).and_return(false)
        result = client.send_sms(from, to, message)
        expect(result).to eq(false)
        expect(logger).to have_received(:warn).with('[MegalabsSms] Stubbed error: SMS not sent')
      end
    end
  end

  context 'with real HTTP request' do
    let(:success_stub) { false }
    let(:error_stub)   { false }
    let(:valid_response) do
      '{"result":{"msg_id":"id","status":{"code":0,"description":"ok"}}}'
    end

    it 'makes an HTTP request and returns true on success' do
      stub_request(:post, 'https://a2p-api.megalabs.ru/sms/v1/sms')
        .to_return(status: 200, body: valid_response, headers: { 'Content-Type': 'application/json' })

      allow(logger).to receive(:info).and_return(true)

      result = client.send_sms(from, to, message)
      expect(result).to eq(true)
      expect(WebMock).to have_requested(:post, 'https://a2p-api.megalabs.ru/sms/v1/sms')
        .with(body: {
          from: from,
          # rubocop:disable Style/NumericLiterals
          to: 70001234567,
          # rubocop:enable Style/NumericLiterals
          message: message
        }.to_json)
      expect(logger).to have_received(:info).with("[MegalabsSms] Successfully sent: #{valid_response}")
    end

    it 'returns false when the API returns an error' do
      error_response = '{"result":{"msg_id":"id","status":{"code":1,"description":"error"}}}'

      stub_request(:post, 'https://a2p-api.megalabs.ru/sms/v1/sms')
        .to_return(status: 200, body: error_response, headers: { 'Content-Type': 'application/json' })

      allow(logger).to receive(:warn).and_return(false)

      result = client.send_sms(from, to, message)
      expect(result).to eq(false)
      expect(logger).to have_received(:warn).with("[MegalabsSms] Failed to send: #{error_response}")
    end
  end

  describe 'keyword arguments compatibility' do
    let(:success_stub) { true }
    let(:error_stub)   { false }

    it 'accepts keyword arguments' do
      allow(logger).to receive(:info).and_return(true)
      result = client.send_sms(from: from, to: to, message: message)
      expect(result).to eq(true)
    end

    it 'raises when mixing positional and keyword arguments' do
      expect do
        client.send_sms(from, to, message, from: from)
      end.to raise_error(ArgumentError, 'use either keyword arguments or positional arguments, not both')
    end
  end
end

# rubocop:enable Metrics/BlockLength
