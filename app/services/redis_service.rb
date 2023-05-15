# frozen_string_literal: true

# app/services/redis_service.rb

class RedisService
  def self.client
    @client ||= begin
      config = YAML.load_file(Rails.root.join('config', 'redis.yml'))[Rails.env]
      Redis.new(host: config['host'], port: config['port'], db: config['db'])
    end
  end
end
