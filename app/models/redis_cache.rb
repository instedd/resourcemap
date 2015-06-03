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
      client.scan_each(match: with_prefix(key)) do |key|
        client.del key
      end
    end

    def clear!
      keys = client.scan_each(match: with_prefix('*')).to_a
      client.del(keys) unless keys.empty?
    end

    def with_prefix(key)
      CACHE_PREFIX + key
    end
  end
end

