require 'rails_helper'

RSpec.describe MessagesController, type: :controller do
  let(:callback_url) { "https://1c25-2600-1702-211f-5610-acca-4082-c904-9bb8.ngrok-free.app/messages/callback" }
  let(:valid_attributes) {
    { to_number: '1234567890', callback_url: callback_url, message: 'Test message' }
  }

  let(:invalid_attributes) {
    { to_number: '', callback_url: '', message: '' }
  }

  describe 'GET #index' do
    it 'returns a success response' do
      Message.create! valid_attributes
      get :index
      expect(response).to be_successful
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      before do
        stub_request(:post, "https://mock-text-provider.parentsquare.com/provider1")
          .to_return(status: 200, body: { message_id: '123' }.to_json, headers: {})

        stub_request(:post, "https://mock-text-provider.parentsquare.com/provider2")
          .to_return(status: 200, body: { message_id: '123' }.to_json, headers: {})
      end

      it 'creates a new Message' do
        expect {
          post :create, params: { message: valid_attributes }
        }.to change(Message, :count).by(1)
      end
    end

    context 'with invalid params' do
      it 'does not create a new Message' do
        expect {
          post :create, params: { message: invalid_attributes }
        }.to change(Message, :count).by(0)
      end
    end
  end

  describe "POST #create with failover" do
    let!(:message) { Message.create!(to_number: '1234567890', callback_url: callback_url, message: 'Test message', provider: MessageSenderService::PROVIDERS[0]) }

    context "when the primary provider fails" do
      before do
        stub_request(:post, MessageSenderService::PROVIDERS[0])
          .to_return(status: 500, body: "Something went wrong.")

        stub_request(:post, MessageSenderService::PROVIDERS[1])
          .to_return(status: 200, body: '{"message_id": "123"}')
      end

      it 'uses the failover provider' do
        post :create, params: { message: valid_attributes }
        message = Message.last
        expect(message.provider).to eq(MessageSenderService::PROVIDERS[1])
        expect(message.external_id).to eq("123")
      end
    end
  end

  describe "POST #callback with failover" do
    let!(:message) { Message.create!(to_number: '1234567890', callback_url: callback_url, message: 'Test message', provider: MessageSenderService::PROVIDERS[0], external_id: '123') }

    context "when the message fails" do
      before do
        stub_request(:post, "#{MessageSenderService::PROVIDERS[1]}")
          .with(
            body: {
              "to_number" => message.to_number,
              "message" => message.message,
              "callback_url" => message.callback_url
            }.to_json
          )
          .to_return(status: 200, body: '{"message_id": "123"}')

        stub_request(:post, "#{MessageSenderService::PROVIDERS[1]}/messages/#{message.external_id}")
          .to_return(status: 200, body: '{"message_id": "123"}')
      end

      it 'uses the failover provider' do
        post :callback, params: { message_id: message.external_id, status: 'failed' }
        expect(message.reload.provider).to eq(MessageSenderService::PROVIDERS[1])
        expect(message.external_id).to eq("123")
      end
    end
  end


end