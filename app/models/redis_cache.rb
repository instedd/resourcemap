class RedisCache
  CACHE_PREFIX = "cache:#{Rails.env}:"

  def self.client
    @@client ||= Redis.new
  end

  def self.cache(key, etag, &block)
    client = self.client
    cache_tag, value = client.hmget CACHE_PREFIX + key, :etag, :value
    if etag.to_s != cache_tag or value.nil?
      value = yield
      #client.hmset CACHE_PREFIX + key, :etag, etag, :value, Marshal.dump(value)
      client.hmset CACHE_PREFIX + key, :etag, etag, :value, value.to_msgpack
      value
    else
      #Marshal.load(value)
      MessagePack.unpack(value)
    end
  end

  def self.evict(key)
    client.scan_each(match: CACHE_PREFIX + key) do |key|
      client.del key
    end
  end

  def self.clear!
    keys = client.scan_each(match: CACHE_PREFIX + '*').to_a
    client.del(keys) unless keys.empty?
  end
end

