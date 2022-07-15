require 'rails_helper'

RSpec.describe 'Applications API', type: :request do
  # initialize test data
  let!(:applications) { create_list(:application, 10) }
  let(:token) { applications.first.token }

  # Test suite for GET /applications
  describe 'GET /applications' do
    # make HTTP get request before each example
    before { get '/applications' }

    it 'should return applications' do
      expect(json).not_to be_empty
      expect(json.size).to eq(10)
    end

    it 'should return application name, token, and chats_count' do
      json.each do |application|
        expect(application["name"]).not_to be(nil)
        expect(application["token"]).not_to be(nil)
        expect(application["chats_count"]).not_to be(nil)
      end
    end

    it 'should return status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  # Test suite for GET /applications/:token
  describe 'GET /applications/:token' do
    before { get "/applications/#{token}" }

    context 'when the record exists' do
      it 'should return the application' do
        expect(json).not_to be_empty
        expect(json['token']).to eq(token)
      end

      it 'should return status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'when the record does not exist' do
      let(:token) { 'invalid_token' }

      it 'should return status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'should return a not found message' do
        expect(response.body).to match(/No Application record exists with given parameter/)
      end
    end
  end

  # Test suite for POST /applications
  describe 'POST /applications' do
    # valid payload
    let(:valid_attributes) { { name: 'New Application' } }

    context 'when the request is valid' do
      before { post '/applications', params: valid_attributes }

      it 'should create a new application' do
        expect(json['name']).to eq('New Application')
        expect(json['token']).not_to be_empty
        expect(json['id']).to eq(nil)
        expect(Application.all.size).to eq(11)
      end

      it 'should return status code 201' do
        expect(response).to have_http_status(201)
      end
    end

    context 'when the request is invalid' do
      before { post '/applications', params: {} }

      it 'should return status code 422' do
        expect(response).to have_http_status(422)
      end

      it 'should return a validation failure message' do
        expect(response.body)
          .to match(/Validation failed: Name can't be blank/)
      end
    end
  end

  # Test suite for PUT /applications/:token
  describe 'PUT /applications/:token' do
    let(:valid_attributes) { { name: 'Updated application' } }

    context 'when the application exists' do
      before { put "/applications/#{token}", params: valid_attributes }

      it 'should update the application' do
        expect(response.body).to be_empty
        expect(Application.find_by!(token: token).name).to eq('Updated application')
      end

      it 'should return status code 204' do
        expect(response).to have_http_status(204)
      end
    end
  end

  # Test suite for DELETE /applications/:token
  describe 'DELETE /applications/:token' do
    before { delete "/applications/#{token}" }

    it 'should return status code 204' do
      expect(response).to have_http_status(204)
    end

    it 'should delete the record from database' do
      expect(Application.find_by(token: token)).to be(nil)
    end
  end
end