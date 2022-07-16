class ChatsController < ApplicationController
  before_action :set_application
  before_action :set_application_chat, only: [:show, :destroy]

  # GET /applications/:application_token/chats
  def index
    json_response(@application.chats.paginate(page: params[:page], per_page: 20))
  end

  # GET /applications/:application_token/chats/:number
  def show
    json_response(@chat)
  end

  # POST /applications/:application_token/chats
  def create
    chat_number = RedisHandlerService.get_chat_number(@application.id)
    ChatPublisher.publish({ number: chat_number, application_id: @application.id, messages_count: 0 }.to_json)
    json_response({ number: chat_number }, :created)
  end

  # DELETE /applications/:application_token/chats/:number
  def destroy
    @chat.destroy
    RedisHandlerService.decrement_chats_count(@chat.application_id)
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
