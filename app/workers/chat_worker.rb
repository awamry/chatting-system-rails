class ChatWorker
  include Sneakers::Worker
  # TODO handle corner cases related to exceptions thrown (UK violation, DB connection failure) and decide whether to ack! or requeue!
  from_queue "chats"
  def work(message)
    chat_json = JSON.parse(message)
    ActiveRecord::Base.connection_pool.with_connection do
      Chat.new(chat_json).save!
    end
    RedisHandlerService.increment_chats_count(chat_json["application_id"])
    ack!
  end
end