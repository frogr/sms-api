# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MessageSenderService do
  let(:message) { Message.create(to_number: '1234567890', callback_url: callback_url, message: 'Test message') }
  let(:service) { described_class.new(message) }
  let(:callback_url) { 'https://9289-2600-1702-211f-5610-acca-4082-c904-9bb8.ngrok-free.app/messages/callback' }

  describe '#call' do
    before do
      stub_request(:post, MessageSenderService::PROVIDERS[0])
        .to_return(status: 200, body: { message_id: '123' }.to_json, headers: {})

      stub_request(:post, MessageSenderService::PROVIDERS[1])
        .to_return(status: 200, body: { message_id: '123' }.to_json, headers: {})
    end

    it 'sends a message' do
      service.call
      expect(message.reload.external_id).to eq('123')
    end
  end

  describe 'failover Logic' do
    context 'when the primary provider fails' do
      before do
        stub_request(:post, MessageSenderService::PROVIDERS[0])
          .to_return(status: 500, body: 'Something went wrong.')

        stub_request(:post, MessageSenderService::PROVIDERS[1])
          .to_return(status: 200, body: '{"message_id": "123"}')

        @message = Message.create!(to_number: '1234567890', callback_url: callback_url, message: 'Test message',
                                   provider: MessageSenderService::PROVIDERS[0])
      end

      it 'uses the failover provider' do
        original_provider = @message.provider
        MessageSenderJob.perform_now(@message.id)
        @message.reload
        expect(@message.provider).not_to eq(original_provider)
        expect(@message.external_id).to eq('123')
      end
    end
  end
end
