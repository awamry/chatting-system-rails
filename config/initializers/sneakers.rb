Sneakers.configure({ :amqp => "amqp://guest:guest@#{Rails.configuration.rabbitmq.host}:#{Rails.configuration.rabbitmq.port}" })
Sneakers.logger.level = Logger::INFO