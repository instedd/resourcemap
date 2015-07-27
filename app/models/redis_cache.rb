class RedisCache
  CACHE_PREFIX = "cache:#{Rails.env}:"

  class << self
    def client
      @client ||= Redis.new
    end

    def cache(key, etag, &block)
      cache_tag, value = client.hmget with_prefix(key), :etag, :value
      if etag.to_s != cache_tag or value.nil?
        value = yield
        client.hmset with_prefix(key), :etag, etag, :value, value.to_msgpack
        value
      else
        MessagePack.unpack(value)
      end
    end

    def evict(key)
      keys = client.keys(with_prefix(key))
      client.del(keys) unless keys.empty?
    end

    def clear!
      keys = client.keys(with_prefix('*'))
      client.del(keys) unless keys.empty?
    end

    def with_prefix(key)
      CACHE_PREFIX + key
    end
  end
end

