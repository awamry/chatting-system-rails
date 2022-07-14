Sneakers.configure({ :amqp => "amqp://guest:guest@#{Rails.configuration.rabbitmq.host}:#{Rails.configuration.rabbitmq.port}", :exchange => "chatting_system" })
Sneakers.logger.level = Logger::INFO