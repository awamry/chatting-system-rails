BUNNY = ConnectionPool.new(size: 20) do
  Bunny.new(host: Rails.configuration.rabbitmq.host, port: Rails.configuration.rabbitmq.port)
end
