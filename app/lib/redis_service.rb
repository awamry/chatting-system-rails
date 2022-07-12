class RedisService
  CHAT_NUMBER_KEY = "chat_number_key"
  MESSAGE_NUMBER_KEY = "message_number_key"
  def self.get_chat_number(application_token)
    $namespaced_redis.incr("#{CHAT_NUMBER_KEY}:#{application_token}")
  end
  def self.get_message_number(chat_number, application_token)
    $namespaced_redis.incr("#{MESSAGE_NUMBER_KEY}:#{chat_number}:#{application_token}")
  end
end