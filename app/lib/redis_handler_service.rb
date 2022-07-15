class RedisHandlerService
  CHAT_NUMBER_KEY = "chat_number"
  MESSAGE_NUMBER_KEY = "message_number"
  CHATS_COUNT_KEY = "chats_count"
  MESSAGES_COUNT_KEY = "messages_count"
  HASH_VALUE_KEY = 'value'
  HASH_IS_FLUSHED_TO_DB_KEY = 'is_flushed_to_db'

  def self.set(key, value)
    REDIS.with do |connection|
      connection.set(key, value)
    end
  end

  def self.increment(key)
    REDIS.with do |connection|
      connection.incr(key)
    end
  end

  def self.key_exists?(key)
    REDIS.with do |connection|
      connection.exists(key) === 1
    end
  end

  def self.get_chat_number(application_id)
    increment("#{CHAT_NUMBER_KEY}:#{application_id}")
  end

  def self.get_message_number(chat_id)
    increment("#{MESSAGE_NUMBER_KEY}:#{chat_id}")
  end

  def self.increment_chats_count(application_id)
    key = "#{CHATS_COUNT_KEY}:#{application_id}"
    result = update_hash(key)
    return result[0]
  end

  def self.decrement_chats_count(application_id)
    key = "#{CHATS_COUNT_KEY}:#{application_id}"
    if key_exists?(key)
      update_hash(key, -1)
    end
  end

  def self.increment_messages_count(chat_id)
    key = "#{MESSAGES_COUNT_KEY}:#{chat_id}"
    result = update_hash(key)
    return result[0]
  end

  def self.decrement_messages_count(chat_id)
    key = "#{MESSAGES_COUNT_KEY}:#{chat_id}"
    if key_exists?(key)
      update_hash(key, -1)
    end
  end

  def self.update_hash(key, increment_value = 1)
    REDIS.with do |connection|
      connection.multi do |multi|
        multi.hincrby(key, HASH_VALUE_KEY, increment_value)
        multi.hset(key, HASH_IS_FLUSHED_TO_DB_KEY, 'false')
      end
    end
  end

  def self.get_chats_count_keys
    REDIS.with do |connection|
      connection.keys("#{CHATS_COUNT_KEY}:*")
    end
  end

  def self.get_messages_count_keys
    REDIS.with do |connection|
      connection.keys("#{MESSAGES_COUNT_KEY}:*")
    end
  end

  def self.set_is_flushed_to_db(key)
    REDIS.with do |connection|
      connection.hset(key, HASH_IS_FLUSHED_TO_DB_KEY, 'true') if key_exists?(key)
    end
  end

  def self.get_hash_values(key)
    REDIS.with do |connection|
      connection.hmget(key, HASH_VALUE_KEY, HASH_IS_FLUSHED_TO_DB_KEY)
    end
  end

end