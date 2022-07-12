class RedisService
  CHAT_NUMBER_KEY = "chat_number_key"
  def self.get_chat_number(application_token)
    $namespaced_redis.incr("#{CHAT_NUMBER_KEY}:#{application_token}")
  end
end