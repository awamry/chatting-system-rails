class MessagesController < ApplicationController
  before_action :set_application
  before_action :set_application_chat
  before_action :set_chat_message, only: [:show, :update, :destroy]

  # GET /applications/:application_token/chats/:chat_number/messages
  def index
    json_response(@chat.messages.paginate(page: params[:page], per_page: 20))
  end

  # GET /applications/:application_token/chats/:chat_number/messages/body/search
  def search_message_body
    results = Message.search_message_body(params[:q], @chat.id)
    render json: results, each_serializer: ElasticSearchMessageSerializer
  end

  # GET /applications/:application_token/chats/:chat_number/messages/:number
  def show
    json_response(@message)
  end

  # PUT /applications/:application_token/chats/:chat_number/messages/:number
  def update
    @message.update(message_params)
    head :no_content
  end

  # POST /applications/:application_token/chats/:chat_number/messages
  def create
    # TODO publish to RabbitMQ queue
    # TODO incr messages_count in (redis || worker)
    json_response({ number: RedisService.get_message_number(@chat.number, @application.token) }, :created)
  end

  # DELETE /applications/:application_token/chats/:chat_number/messages/:number
  def destroy
    @message.destroy
    head :no_content
  end

  private

  def set_application
    @application = Application.find_by!(token: params[:application_token])
  end

  def set_application_chat
    @chat = @application.chats.find_by!(number: params[:chat_number]) if @application
  end

  def set_chat_message
    @message = @chat.messages.find_by!(number: params[:number]) if @chat
  end

  def message_params
    # whitelist params
    params.permit(:body)
  end
end
