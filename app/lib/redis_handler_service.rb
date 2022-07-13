class RedisHandlerService
  CHAT_NUMBER_KEY = "chat_number"
  MESSAGE_NUMBER_KEY = "message_number"
  CHATS_COUNT_KEY = "chats_count"
  MESSAGES_COUNT_KEY = "messages_count"

  def self.set(key, value)
    $namespaced_redis.set(key, value)
  end

  def self.increment(key)
    $namespaced_redis.incr(key)
  end

  def self.key_exists?(key)
    $namespaced_redis.exists?(key)
  end

  def self.get_chat_number(application_id)
    increment("#{CHAT_NUMBER_KEY}:#{application_id}")
  end

  def self.get_message_number(chat_id)
    increment("#{MESSAGE_NUMBER_KEY}:#{chat_id}")
  end

  def self.increment_chats_count(application_id)
    if key_exists?("#{CHATS_COUNT_KEY}:#{application_id}")
      $namespaced_redis.multi do |multi|
        multi.incr("#{CHATS_COUNT_KEY}:#{application_id}")
        multi.expire("#{CHATS_COUNT_KEY}:#{application_id}", 10)
      end[0]
    else
      chats_count = Application.find(application_id).chats.size
      if key_exists?("#{CHATS_COUNT_KEY}:#{application_id}")
        $namespaced_redis.multi do |multi|
          multi.incr("#{CHATS_COUNT_KEY}:#{application_id}")
          multi.expire("#{CHATS_COUNT_KEY}:#{application_id}", 10)
        end[0]
      else
        $namespaced_redis.multi do |multi|
          multi.set("#{CHATS_COUNT_KEY}:#{application_id}", chats_count + 1)
          multi.expire("#{CHATS_COUNT_KEY}:#{application_id}", 10)
        end
        return chats_count + 1
      end
    end
  end

  def self.increment_messages_count(chat_id)
    if key_exists?("#{MESSAGES_COUNT_KEY}:#{chat_id}")
      increment("#{MESSAGES_COUNT_KEY}:#{chat_id}")
    else
      messages_count = Chat.find("#{MESSAGES_COUNT_KEY}:#{chat_id}").messages.size
      if key_exists?("#{MESSAGES_COUNT_KEY}:#{chat_id}")
        increment("#{MESSAGES_COUNT_KEY}:#{chat_id}")
      else
        set("#{MESSAGES_COUNT_KEY}:#{chat_id}", messages_count + 1)
        return messages_count + 1
      end
    end
  end

end