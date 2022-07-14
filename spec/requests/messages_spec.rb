require 'rails_helper'

RSpec.describe 'Messages API', type: :request do
  # Initialize the test data
  let!(:application) { create(:application) }
  let!(:chat) { create(:chat, application_id: application.id) }
  let!(:messages) { create_list(:message, 20, chat_id: chat.id) }
  let(:application_token) { application.token }
  let(:chat_number) { chat.number }
  let(:number) { messages.first.number }

  # Test suite for GET /application/:application_token/chats/:chat_number/messages
  describe 'GET /application/:application_token/chats/:chat_number/messages' do
    before { get "/applications/#{application_token}/chats/#{chat_number}/messages" }

    context 'when chat exists' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns all chat messages' do
        expect(json.size).to eq(20)
      end
    end

    context 'when chat does not exist' do
      let(:chat_number) { 0 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/No Chat record exists with given parameter/)
      end
    end
  end

  # Test suite for GET /applications/:application_token/chats/:chat_number/messages/:number
  describe 'GET /applications/:application_token/chats/:chat_number/messages/:number' do
    before { get "/applications/#{application_token}/chats/#{chat_number}/messages/#{number}" }

    context 'when application chat exists' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns the message' do
        expect(json['number']).to eq(number)
      end
    end

    context 'when application chat does not exist' do
      let(:number) { 0 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/No Message record exists with given parameter/)
      end
    end
  end

  # Test suite for POST /applications/:application_token/chats/:chat_number/messages
  describe 'POST /applications/:application_token/chats/:chat_number/messages' do
    let(:valid_attributes) { {body: 'Message body'}.to_json }

    context 'when request attributes are valid' do
      before { post "/applications/#{application_token}/chats/#{chat_number}/messages", params: valid_attributes }

      it 'returns status code 201' do
        BUNNY.with do |connection|
          connection.start
          channel = connection.create_channel
          expect(connection.exchange_exists?("chatting_system")).to be_truthy
          expect(connection.queue_exists?("messages")).to be_truthy
          expect(channel.queue("messages").message_count).to eq(1)
        end
        expect(response).to have_http_status(201)
      end
    end

  end

  # Test suite for PUT /applications/:application_token/chats/:chat_number/messages/:number
  describe 'PUT /applications/:application_token/chats/:chat_number/messages/:number' do
    let(:valid_attributes) { { body: 'New body' } }

    context 'when the record exists' do
      before { put "/applications/#{application_token}/chats/#{chat_number}/messages/#{number}", params: valid_attributes }

      it 'updates the record' do
        expect(response.body).to be_empty
      end

      it 'returns status code 204' do
        expect(response).to have_http_status(204)
      end
    end
  end

  # Test suite for DELETE /applications/:id
  describe 'DELETE /applications/:number' do
    before { delete "/applications/#{application_token}/chats/#{chat_number}/messages/#{number}" }

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end
  end
end