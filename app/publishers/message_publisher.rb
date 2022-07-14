class MessagePublisher
  def self.publish(message)
    BUNNY.with do |connection|
      connection.start
      channel = connection.create_channel
      exchange = channel.exchange("chatting_system", durable: true)
      queue = channel.queue("messages", durable: true).bind(exchange, :routing_key => "messages")
      channel.confirm_select
      exchange.publish(message, :routing_key => queue.name, :persistent => true)
      unless channel.wait_for_confirms
        channel.close
        raise StandardError.new "Unable to publish message"
      end
      channel.close
    end
  end
end