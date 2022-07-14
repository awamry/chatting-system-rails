class MessageWorker
  include Sneakers::Worker
  # TODO handle corner cases related to exceptions thrown (UK violation, DB connection failure) and decide whether to ack! or requeue!
  from_queue "chatting_system_messages"
  def work(message)
    message_json = JSON.parse(message)
    Message.new(message_json).save!
    RedisHandlerService.increment_messages_count(message_json["chat_id"])
    ack!
  end
end