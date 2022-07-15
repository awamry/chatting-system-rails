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
      it 'should return all application chats' do
        expect(json.size).to eq(20)
      end
      it 'should return number and messages_count' do
        json.each do |chat|
          expect(chat["number"]).not_to be(nil)
          expect(chat["messages_count"]).not_to be(nil)
        end
      end

      it 'should return status code 200' do
        expect(response).to have_http_status(200)
      end

    end

    context 'when application does not exist' do
      let(:application_token) { 'invalid_token' }

      it 'should return status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'should return a not found message' do
        expect(response.body).to match(/No Application record exists with given parameter/)
      end
    end
  end

  # Test suite for GET /applications/:application_token/chats/:number
  describe 'GET /applications/:application_token/chats/:number' do
    before { get "/applications/#{application_token}/chats/#{number}" }

    context 'when application chat exists' do
      it 'should return status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'should return the chat' do
        expect(json['number']).to eq(number)
      end
    end

    context 'when application chat does not exist' do
      let(:number) { 0 }

      it 'should return status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'should return a not found message' do
        expect(response.body).to match(/No Chat record exists with given parameter/)
      end
    end
  end

  # Test suite for POST /applications/:application_token/chats
  describe 'POST /applications/:application_token/chats' do
    let(:valid_attributes) { {} }

    context 'when request attributes are valid' do
      before { post "/applications/#{application_token}/chats", params: valid_attributes }

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
      it 'should create RabbitMQ exchange and queue if not exist' do
        BUNNY.with do |connection|
          connection.start
          channel = connection.create_channel
          expect(connection.exchange_exists?("chatting_system")).to be_truthy
          expect(connection.queue_exists?("chats")).to be_truthy
          channel.close
        end
      end

      it 'should publish the chat with correct payload to the queue' do
        BUNNY.with do |connection|
          connection.start
          channel = connection.create_channel
          expect(channel.queue("chats").message_count).to eq(1)
          payload = JSON.parse(channel.queue("chats").pop[2])
          expect(payload["application_id"]).to eq(application.id)
          expect(payload["number"]).to eq(1)
          expect(payload["messages_count"]).to eq(0)
          channel.close
        end
      end


      it 'should increment chat_number key of the application_id in redis' do
        REDIS.with do |connection|
          expect(connection.exists("chat_number:#{application.id}")).to be_truthy
          expect(connection.get("chat_number:#{application.id}")).to eq("1")
        end
      end
    end

  end

  # Test suite for DELETE /applications/:id
  describe 'DELETE /applications/:number' do
    before { delete "/applications/#{application_token}/chats/#{number}" }

    it 'should return status code 204' do
      expect(response).to have_http_status(204)
    end

    it 'should delete the record from the database' do
      expect(Chat.find_by(application_id: application.id, number: number)).to be(nil)
    end
  end
end