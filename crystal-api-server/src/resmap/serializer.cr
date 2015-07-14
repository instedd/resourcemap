require "msgpack"
require "../zlib/*"
require "../shims/*"

module Serializer

  class Gzip
    def self.deserialize(input_data : Slice(UInt8))
      return nil unless input_data

      if input_data.length > 0

        zstream = LibZ::ZStream.new
        zs = pointerof(zstream) as LibZ::ZStreamP
        zstream_mem = Slice(UInt8).new(pointerof(zstream) as UInt8*, sizeof(LibZ::ZStream))
        zstream_mem.each_with_index do |e, i|
          zstream_mem[i] = 0u8
        end

        zstream.next_in = input_data.to_unsafe
        zstream.avail_in = input_data.length.to_u32
        zstream.total_in = input_data.length.to_culong

        buffer = Slice(UInt8).new(input_data.length * 1000)
        zstream.next_out = buffer.to_unsafe
        zstream.avail_out = buffer.length.to_u32
        zstream.total_out = buffer.length.to_culong

        zstream.zalloc = nil as Void*
        zstream.zfree = nil as Void*
        zstream.opaque = nil as Void*


        # 15 window bits, and the +32 tells zlib to to detect if using gzip or zlib
        res = LibZ.inflateInit2_(zs, 15+32, LibZ.version(), sizeof(LibZ::ZStream))
        # puts res # 0 == Z_OK

        res = LibZ.inflate(zs, LibZ::Z_FINISH)
        # puts res # 1 == Z_STREAM_END

        buffer2 = Slice(UInt8).new(buffer.to_unsafe, zstream.total_out.to_i)

        buffer2
      else
        nil
      end
    end
  end

  class Msgpack
    def self.deserialize(input_data)
      return nil unless input_data

      MessagePack.unpack(SliceIO(UInt8).new(input_data))
    end
  end
end
