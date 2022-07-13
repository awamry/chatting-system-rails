class RedisHandlerService
  CHAT_NUMBER_KEY = "chat_number"
  MESSAGE_NUMBER_KEY = "message_number"
  CHATS_COUNT_KEY = "chats_count"
  MESSAGES_COUNT_KEY = "messages_count"
  HASH_VALUE_KEY = 'value'
  HASH_EXPIRATION_DATE_KEY = 'expiration_date'
  HASH_IS_FLUSHED_TO_DB_KEY = 'is_flushed_to_db'

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
    key = "#{CHATS_COUNT_KEY}:#{application_id}"
    if key_exists?(key)
      result = update_hash(key)
      return result[0]
    else
      chats_count = Application.find(application_id).chats.size
      if key_exists?(key)
        result = update_hash(key)
        return result[0]
      end
      $namespaced_redis.hmset(
        "#{CHATS_COUNT_KEY}:#{application_id}", HASH_VALUE_KEY,
        chats_count + 1, HASH_EXPIRATION_DATE_KEY, Time.now.to_i + (3 * 60 * 60),
        HASH_IS_FLUSHED_TO_DB_KEY, 'false'
      )
      return chats_count + 1
    end
  end

  def self.increment_messages_count(chat_id)
    key = "#{MESSAGES_COUNT_KEY}:#{chat_id}"
    if key_exists?(key)
      $namespaced_redis.multi do |multi|
        result = update_hash(key)
        return result[0]
      end
    else
      messages_count = Chat.find(chat_id).messages.size
      if key_exists?(key)
        result = update_hash(key)
        return result[0]
      else
        $namespaced_redis.hmset(
          "#{MESSAGES_COUNT_KEY}:#{chat_id}", HASH_VALUE_KEY,
          chats_count + 1, HASH_EXPIRATION_DATE_KEY, Time.now.to_i + (3 * 60 * 60),
          HASH_IS_FLUSHED_TO_DB_KEY, 'false'
        )
        return messages_count + 1
      end
    end
  end

  def self.update_hash(key)
    $namespaced_redis.multi do |multi|
      multi.hincrby(key, HASH_VALUE_KEY, 1)
      multi.hset(key, HASH_EXPIRATION_DATE_KEY, Time.now.to_i + (3 * 60 * 60))
      multi.hset(key, HASH_IS_FLUSHED_TO_DB_KEY, 'false')
    end
  end

  def self.get_chats_count_keys
    $namespaced_redis.keys("#{CHATS_COUNT_KEY}:*")
  end

  def self.get_messages_count_keys
    $namespaced_redis.keys("#{MESSAGES_COUNT_KEY}:*")
  end

  def self.get_hash_values(key)
    $namespaced_redis.hmget(key, HASH_VALUE_KEY, HASH_EXPIRATION_DATE_KEY, HASH_IS_FLUSHED_TO_DB_KEY)
  end
end