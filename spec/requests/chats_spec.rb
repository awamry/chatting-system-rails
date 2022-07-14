require 'rails_helper'

RSpec.describe 'Chats API', type: :request do
  # Initialize the test data
  let!(:application) { create(:application) }
  let!(:chats) { create_list(:chat, 20, application_id: application.id) }
  let(:application_token) { application.token }
  let(:number) { chats.first.number }

  # Test suite for GET /application/:application_token/chats
  describe 'GET /application/:application_token/chats' do
    before { get "/applications/#{application_token}/chats" }

    context 'when application exists' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns all application chats' do
        expect(json.size).to eq(20)
      end
    end

    context 'when application does not exist' do
      let(:application_token) { 'invalid_token' }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/No Application record exists with given parameter/)
      end
    end
  end

  # Test suite for GET /applications/:application_token/chats/:number
  describe 'GET /applications/:application_token/chats/:number' do
    before { get "/applications/#{application_token}/chats/#{number}" }

    context 'when application chat exists' do
      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'returns the chat' do
        expect(json['number']).to eq(number)
      end
    end

    context 'when application chat does not exist' do
      let(:number) { 0 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/No Chat record exists with given parameter/)
      end
    end
  end

  # Test suite for PUT /applications/:application_token/chats
  describe 'POST /applications/:application_token/chats' do
    let(:valid_attributes) { {} }

    context 'when request attributes are valid' do
      before { post "/applications/#{application_token}/chats", params: valid_attributes }

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
        BUNNY.with do |connection|
          connection.start
          channel = connection.create_channel
          expect(connection.exchange_exists?("chatting_system")).to be_truthy
          expect(connection.queue_exists?("chats")).to be_truthy
          expect(channel.queue("chats").message_count).to eq(1)
        end
      end
    end

  end

  # Test suite for DELETE /applications/:id
  describe 'DELETE /applications/:number' do
    before { delete "/applications/#{application_token}/chats/#{number}" }

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end
  end
end