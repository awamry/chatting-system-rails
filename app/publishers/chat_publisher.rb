class ChatPublisher
  def self.publish(chat)
    BUNNY.with do |connection|
      connection.start
      channel = connection.create_channel
      exchange = channel.exchange("chatting_system", durable: true)
      queue = channel.queue("chats", durable: true).bind(exchange, :routing_key => "chats")
      exchange.publish(chat, :routing_key => queue.name)
      channel.close
    end
  end
end