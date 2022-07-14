class ChatPublisher
  def self.publish(chat)
    BUNNY.with do |connection|
      connection.start
      channel = connection.create_channel
      exchange = channel.exchange("chatting_system", durable: true)
      queue = channel.queue("chats", durable: true).bind(exchange, :routing_key => "chats")
      channel.confirm_select
      exchange.publish(chat, :routing_key => queue.name, :persistent => true)
      unless channel.wait_for_confirms
        channel.close
        raise StandardError.new "Unable to publish chat"
      end
      channel.close
    end
  end
end