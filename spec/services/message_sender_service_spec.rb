# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MessageSenderService do
  let(:message) { Message.create(to_number: '1234567890', callback_url: 'https://1c25-2600-1702-211f-5610-acca-4082-c904-9bb8.ngrok-free.app/messages/callback', message: 'Test message') }
  let(:service) { described_class.new(message) }

  describe '#call' do
    before do
      stub_request(:post, 'https://mock-text-provider.parentsquare.com/provider1')
        .to_return(status: 200, body: { message_id: '123' }.to_json, headers: {})

      stub_request(:post, 'https://mock-text-provider.parentsquare.com/provider2')
        .to_return(status: 200, body: { message_id: '123' }.to_json, headers: {})
    end

    it 'sends a message' do
      service.call
      expect(message.reload.external_id).to eq('123')
    end
  end
end
