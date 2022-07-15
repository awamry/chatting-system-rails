class RedisHandlerService
  CHAT_NUMBER_KEY = "chat_number"
  MESSAGE_NUMBER_KEY = "message_number"
  CHATS_COUNT_KEY = "chats_count"
  MESSAGES_COUNT_KEY = "messages_count"
  HASH_VALUE_KEY = 'value'
  HASH_EXPIRATION_DATE_KEY = 'expiration_date'
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
    if key_exists?(key)
      result = update_hash(key)
      return result[0]
    else
      chats_count = Application.find(application_id).chats.size
      if key_exists?(key)
        result = update_hash(key)
        return result[0]
      end
      REDIS.with do |connection|
        connection.hmset(
          key,
          HASH_VALUE_KEY, chats_count,
          HASH_EXPIRATION_DATE_KEY, Time.now.to_i + (3 * 60 * 60),
          HASH_IS_FLUSHED_TO_DB_KEY, 'false'
        )
      end
      return chats_count
    end
  end

  def self.decrement_chats_count(application_id)
    key = "#{CHATS_COUNT_KEY}:#{application_id}"
    if key_exists?(key)
      update_hash(key, -1)
    end
  end

  def self.increment_messages_count(chat_id)
    key = "#{MESSAGES_COUNT_KEY}:#{chat_id}"
    if key_exists?(key)
      result = update_hash(key)
      return result[0]
    else
      messages_count = Chat.find(chat_id).messages.size
      if key_exists?(key)
        result = update_hash(key)
        return result[0]
      else
        REDIS.with do |connection|
          connection.hmset(
            key,
            HASH_VALUE_KEY, messages_count,
            HASH_EXPIRATION_DATE_KEY, Time.now.to_i + (3 * 60 * 60),
            HASH_IS_FLUSHED_TO_DB_KEY, 'false'
          )
        end
        return messages_count
      end
    end
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
        multi.hset(key, HASH_EXPIRATION_DATE_KEY, Time.now.to_i + (3 * 60 * 60))
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
      connection.hmget(key, HASH_VALUE_KEY, HASH_EXPIRATION_DATE_KEY, HASH_IS_FLUSHED_TO_DB_KEY)
    end
  end

  def self.delete(key)
    REDIS.with do |connection|
      connection.del(key)
    end
  end
end