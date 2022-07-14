class FailedMessagesHandler

  # This is somehow like a dead letter exchange that will store chats and messages that have failed to be inserted for multiple reasons
  # e.g
  # 1- DB connectivity failure
  # 2- Unique key constraint error for chats (application_id, number) or for messages (chat_id, number)
  # which could happen if Redis became out-of-sync due to restart
  # (message number or chat number could be duplicated when fetching it from redis as we don't have strict consistency guarantee when using AOF)
  # Those cases are not going to frequently happen but they need to be considered at the end.
  def self.push_to_failed_queue(payload, queue)
    BUNNY.with do |connection|
      connection.start
      channel = connection.create_channel
      exchange = channel.exchange("chatting_system_failure", durable: true)
      queue = channel.queue(queue, durable: true).bind(exchange, :routing_key => queue)
      exchange.publish(payload, :routing_key => queue.name, :persistent => true)
      channel.close
    end

  end
end