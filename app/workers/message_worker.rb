class MessageWorker
  include Sneakers::Worker
  # TODO handle corner cases related to exceptions thrown (UK violation, DB connection failure) and decide whether to ack! or requeue!
  from_queue "messages"
  def work(message)
    message_json = JSON.parse(message)
    ActiveRecord::Base.connection_pool.with_connection do
      Message.new(message_json).save!
    end
    RedisHandlerService.increment_messages_count(message_json["chat_id"])
    ack!
  end
end