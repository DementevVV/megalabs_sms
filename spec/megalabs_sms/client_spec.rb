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

  subject(:client) do
    described_class.new(
      api_user,
      api_password,
      sleep_time: sleep_time,
      success_stub: success_stub,
      error_stub: error_stub
    )
  end

  context 'with stub responses' do
    context 'when success_stub is true' do
      let(:success_stub) { true }
      let(:error_stub)   { false }

      it 'returns a success message (stub)' do
        result = client.send_sms(from, to, message)
        expect(result).to eq('[MegalabsSms] Stubbed success: SMS would be sent')
      end
    end

    context 'when error_stub is true' do
      let(:success_stub) { false }
      let(:error_stub)   { true }

      it 'returns an error message (stub)' do
        result = client.send_sms(from, to, message)
        expect(result).to eq('[MegalabsSms] Stubbed error: SMS not sent')
      end
    end
  end

  context 'with real HTTP request' do
    let(:success_stub) { false }
    let(:error_stub)   { false }
    let(:valid_response) do
      '{"result":{"msg_id":"id","status":{"code":0,"description":"ok"}}}'
    end

    it 'makes an HTTP request' do
      stub_request(:post, 'https://a2p-api.megalabs.ru/sms/v1/sms')
        .to_return(status: 200, body: valid_response, headers: { 'Content-Type': 'application/json' })

      result = client.send_sms(from, to, message)
      expect(result).to eq(valid_response)
      expect(WebMock).to have_requested(:post, 'https://a2p-api.megalabs.ru/sms/v1/sms')
        .with(body: {
          from: from,
          # rubocop:disable Style/NumericLiterals
          to: 70001234567,
          # rubocop:enable Style/NumericLiterals
          message: message
        }.to_json)
    end
  end
end

# rubocop:enable Metrics/BlockLength
