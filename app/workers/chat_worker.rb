class ChatWorker
  include Sneakers::Worker
  from_queue "chats"

  def work(message)
    begin
      chat_json = JSON.parse(message)
      ActiveRecord::Base.connection_pool.with_connection do
        Chat.new(chat_json).save!
      end
      RedisHandlerService.increment_chats_count(chat_json["application_id"])
      ack!
    rescue Exception => e
      puts "Error while persisting chat #{e.message}"
      FailedMessagesHandler.push_to_failed_queue(message, 'failed_chats')
    end
  end
end