class MessageWorker
  include Sneakers::Worker
  from_queue "messages"

  def work(message)
    begin
      message_json = JSON.parse(message)
      ActiveRecord::Base.connection_pool.with_connection do
        Message.new(message_json).save!
      end
      RedisHandlerService.increment_messages_count(message_json["chat_id"])
      ack!
    rescue
      FailedMessagesHandler.push_to_failed_queue(message, 'failed_messages')
    end
  end
end