require 'rails_helper'

RSpec.describe 'Messages API', elasticsearch: true, type: :request do
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
      it 'should return all chat messages' do
        expect(json.size).to eq(20)
      end
      it 'should return number and body' do
        json.each do |message|
          expect(message["number"]).not_to be(nil)
          expect(message["body"]).not_to be(nil)
        end
      end
      it 'should return status code 200' do
        expect(response).to have_http_status(200)
      end


    end

    context 'when chat does not exist' do
      let(:chat_number) { 0 }

      it 'should return status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'should return a not found message' do
        expect(response.body).to match(/No Chat record exists with given parameter/)
      end
    end
  end

  # Test suite for GET /applications/:application_token/chats/:chat_number/messages/:number
  describe 'GET /applications/:application_token/chats/:chat_number/messages/:number' do
    before { get "/applications/#{application_token}/chats/#{chat_number}/messages/#{number}" }

    context 'when application chat exists' do
      it 'should return status code 200' do
        expect(response).to have_http_status(200)
      end

      it 'should return the message' do
        expect(json['number']).to eq(number)
      end
    end

    context 'when application chat does not exist' do
      let(:number) { 0 }

      it 'should return status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'should return a not found message' do
        expect(response.body).to match(/No Message record exists with given parameter/)
      end
    end
  end

  # Test suite for POST /applications/:application_token/chats/:chat_number/messages
  describe 'POST /applications/:application_token/chats/:chat_number/messages' do
    let(:valid_attributes) { {body: 'Message body'}.to_json }

    context 'when request attributes are valid' do
      before { post "/applications/#{application_token}/chats/#{chat_number}/messages", params: valid_attributes }

      it 'should return status code 201' do
        expect(response).to have_http_status(201)
      end

      it 'should create RabbitMQ exchange and queue if not exist' do
        BUNNY.with do |connection|
          connection.start
          channel = connection.create_channel
          expect(connection.exchange_exists?("chatting_system")).to be_truthy
          expect(connection.queue_exists?("messages")).to be_truthy
          channel.close
        end
      end

      it 'should publish the message with correct payload to the queue' do
        BUNNY.with do |connection|
          connection.start
          channel = connection.create_channel
          expect(channel.queue("messages").message_count).to eq(1)
          payload = JSON.parse(channel.queue("messages").pop[2])
          expect(payload["number"]).to eq(1)
          expect(payload["chat_id"]).to eq(chat.id)
          expect(payload["body"]).to eq("Message body")
          channel.close
        end
      end

      it 'should increment message_number key of the chat_id to in' do
        REDIS.with do |connection|
          expect(connection.exists("message_number:#{chat.id}")).to be_truthy
          expect(connection.get("message_number:#{chat.id}")).to eq("1")
        end
      end
    end

  end

  # Test suite for PUT /applications/:application_token/chats/:chat_number/messages/:number
  describe 'PUT /applications/:application_token/chats/:chat_number/messages/:number' do
    let(:valid_attributes) { { body: 'Updated body' } }

    context 'when the record exists' do
      before { put "/applications/#{application_token}/chats/#{chat_number}/messages/#{number}", params: valid_attributes }

      it 'should update the record' do
        expect(response.body).to be_empty
        expect(Message.find_by!(chat_id: chat.id).body).to eq('Updated body')
      end

      it 'should return status code 204' do
        expect(response).to have_http_status(204)
      end
    end
  end

  # Test suite for DELETE /applications/:application_token/chats/:chat_number/messages/:number
  describe 'DELETE /applications/:application_token/chats/:chat_number/messages/:number' do
    before { delete "/applications/#{application_token}/chats/#{chat_number}/messages/#{number}" }

    it 'should return status code 204' do
      expect(response).to have_http_status(204)
    end
    it 'should delete the record from the database' do
      expect(Message.find_by(chat_id: chat.id, number: number)).to be(nil)
    end
  end
end