class SynchronizeRedisWithDatabaseJob
  include Sidekiq::Job
  UPDATE_BATCH_SIZE = 25

  def perform(*args)
    puts "Synchronization task has started at #{Time.now}"
    synchronize_chats_count
    synchronize_messages_count
    puts "Synchronization task has ended at #{Time.now}"

  end

  def synchronize_chats_count
    chats_count_key = RedisHandlerService.get_chats_count_keys
    synchronize_table(Application, 'chats_count', chats_count_key)
  end

  def synchronize_messages_count
    messages_count_keys = RedisHandlerService.get_messages_count_keys
    synchronize_table(Chat, 'messages_count', messages_count_keys)
  end

  def synchronize_table(model, column_name, keys)
    current_timestamp = Time.now.to_i
    records_to_update = []
    keys.each { |key|
      begin
        count, expiration_date, is_counter_flushed_to_db = RedisHandlerService.get_hash_values(key)
        next if count.nil? || expiration_date.nil? || is_counter_flushed_to_db.nil?
        if is_counter_flushed_to_db === 'false'
          records_to_update << { key: key, value: count }
          if records_to_update.size === UPDATE_BATCH_SIZE
            update_in_single_transaction(model, column_name, records_to_update)
            set_is_flushed_to_db(records_to_update)
            records_to_update = []
          end
        end
        if current_timestamp > expiration_date.to_i
          RedisHandlerService.delete(key)
        end
      rescue Exception => e
        puts "An error occurred while processing key #{key}. #{e.message}"
        next
      end
    }
    if records_to_update.size > 0
      update_in_single_transaction(model, column_name, records_to_update)
      set_is_flushed_to_db(records_to_update)
    end
  end

  def update_in_single_transaction(model, column_name, records_to_update)
    ActiveRecord::Base.transaction do
      records_to_update.each { |record|
        id = record[:key].split(":")[-1]
        model.where(id: id).update_all("#{column_name}": record[:value])
      }
    end
  end

  def set_is_flushed_to_db(records)
    records.each { |record|
      RedisHandlerService.set_is_flushed_to_db(record[:key])
    }
  end

end
