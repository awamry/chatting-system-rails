require "redis"

redis = Redis.new(host: Rails.configuration.redis.host, port: Rails.configuration.redis.port, db: Rails.configuration.redis.db )

$namespaced_redis = Redis::Namespace.new('chatting_system', redis: redis)

