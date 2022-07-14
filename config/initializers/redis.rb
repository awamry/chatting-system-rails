require "redis"

redis = Redis.new(host: Rails.configuration.redis.host, port: Rails.configuration.redis.port, db: Rails.configuration.redis.db)

REDIS = ConnectionPool.new(size: 20) do
  Redis::Namespace.new('chatting_system', redis: redis)
end