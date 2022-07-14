class MessagePublisher
  def self.publish(chat)
    BUNNY.with do |connection|
      connection.start
      channel = connection.create_channel
      exchange = channel.exchange("chatting_system", durable: true)
      queue = channel.queue("messages", durable: true).bind(exchange, :routing_key => "messages")
      exchange.publish(chat, :routing_key => queue.name)
      channel.close
    end
  end
end