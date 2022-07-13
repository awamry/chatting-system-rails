namespace :redis do
  desc "Flush counts of chats_count and messages_count values from redis to database"
  task synchronize_counts_with_database: :environment do
    synchronize_chats_count
    synchronize_messages_count
  end

  def synchronize_chats_count
    current_timestamp = Time.now.to_i
    chats_count_key = RedisHandlerService.get_chats_count_keys
    chats_count_key.each { |key|
      count, expiration_date, is_counter_flushed_to_db = RedisHandlerService.get_hash_values(key)
      next if count.nil? || expiration_date.nil? || is_counter_flushed_to_db.nil?
      if is_counter_flushed_to_db === 'false'
        application_id = key.split(":")[-1]
        Application.update(application_id, chats_count: count)
        RedisHandlerService.set_is_flushed_to_db(key)
      end
      if current_timestamp > expiration_date.to_i
        RedisHandlerService.delete(key)
      end
    }
  end

  def synchronize_messages_count
    current_timestamp = Time.now.to_i
    messages_count_keys = RedisHandlerService.get_messages_count_keys
    messages_count_keys.each { |key|
      count, expiration_date, is_counter_flushed_to_db = RedisHandlerService.get_hash_values(key)
      next if count.nil? || expiration_date.nil? || is_counter_flushed_to_db.nil?
      if is_counter_flushed_to_db === 'false'
        chat_id = key.split(":")[-1]
        Chat.update(chat_id, messages_count: count)
        RedisHandlerService.set_is_flushed_to_db(key)
      end
      if current_timestamp > expiration_date.to_i
        RedisHandlerService.delete(key)
      end
    }
  end

end
