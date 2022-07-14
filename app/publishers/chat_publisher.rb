class ChatPublisher
  def self.publish(chat)
    BUNNY.with do |connection|
      connection.start
      channel = connection.create_channel
      queue = channel.queue("chatting_system_chats", durable: true)
      exchange = channel.default_exchange
      exchange.publish(chat, :routing_key => queue.name)
      channel.close
    end
  end
end