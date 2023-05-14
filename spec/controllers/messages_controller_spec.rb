require 'rails_helper'

RSpec.describe MessagesController, type: :controller do
  let(:valid_attributes) {
    { to_number: '1234567890', callback_url: 'http://example.com', message: 'Test message' }
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
          .with(body: "{\"to_number\":\"1234567890\",\"message\":\"Test message\",\"callback_url\":\"http://example.com\"}")
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
end
