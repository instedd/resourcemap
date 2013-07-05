require 'base64'

class MarshalZipSerializable
  def self.dump(x)
    return nil if x.nil?

    Zlib.deflate(Marshal.dump(x), 9)
  end

  def self.load(x)
    return nil if x.nil?

    Marshal.load(Zlib.inflate(x))
  end
end