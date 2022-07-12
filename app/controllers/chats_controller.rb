class ChatsController < ApplicationController
  before_action :set_application
  before_action :set_application_chat, only: [:show, :destroy]

  # GET /applications/:application_token/chats
  def index
    json_response(@application.chats)
  end

  # GET /applications/:application_token/chats/:number
  def show
    json_response(@chat)
  end

  # POST /applications/:application_token/chats
  def create
    # TODO publish to RabbitMQ queue
    # TODO incr chats_count in (redis || worker)
    json_response({number: RedisService.get_chat_number(@application.token)}, :created)
  end

  # DELETE /applications/:application_token/chats/:number
  def destroy
    @chat.destroy
    head :no_content
  end

  private

  def set_application
    @application = Application.find_by!(token: params[:application_token])
  end

  def set_application_chat
    @chat = @application.chats.find_by!(number: params[:number]) if @application
  end
end
