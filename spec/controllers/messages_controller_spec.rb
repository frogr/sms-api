# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MessagesController, type: :controller do
  let(:callback_url) { 'https://9289-2600-1702-211f-5610-acca-4082-c904-9bb8.ngrok-free.app/messages/callback' }
  let(:valid_attributes) do
    { to_number: '1234567890', callback_url: callback_url, message: 'Test message' }
  end

  let(:invalid_attributes) do
    { to_number: '', callback_url: '', message: '' }
  end

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
        stub_request(:post, 'https://mock-text-provider.parentsquare.com/provider1')
          .to_return(status: 200, body: { message_id: '123' }.to_json, headers: {})

        stub_request(:post, 'https://mock-text-provider.parentsquare.com/provider2')
          .to_return(status: 200, body: { message_id: '123' }.to_json, headers: {})
      end

      it 'creates a new Message' do
        expect do
          post :create, params: { message: valid_attributes }
        end.to change(Message, :count).by(1)
      end
    end

    context 'with invalid params' do
      it 'does not create a new Message' do
        expect do
          post :create, params: { message: invalid_attributes }
        end.to change(Message, :count).by(0)
      end
    end
  end
end
