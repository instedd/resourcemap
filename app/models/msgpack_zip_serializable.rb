class MsgpackZipSerializable
  def self.dump(x)
    return nil if x.nil?

    Zlib.deflate(x.to_msgpack, 9)
  end

  def self.load(x)
    return nil if x.nil?

    MessagePack.unpack(Zlib.inflate(x))
  end
end
