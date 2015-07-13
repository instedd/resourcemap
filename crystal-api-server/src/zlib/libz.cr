@[Link("z")] ifdef darwin
@[Link("zlib")] ifdef linux
lib LibZ
  alias CChar = UInt8
  alias CUInt = UInt32
  alias CULong = UInt64
  alias CInt = Int32

  Z_FINISH = 4
  Z_OK = 0

  alias Bytef = UInt8
  struct ZStream
    next_in : Bytef*
    avail_in : CUInt
    total_in : CULong
    next_out : Bytef*
    avail_out : CUInt
    total_out : CULong
    msg : CChar*
    state : Void*
    zalloc : Void* # (Void*, CUInt, CUInt) -> Void*
    zfree : Void* # (Void*, Void*) -> Void
    opaque : Void*
    data_type : CInt
    adler : CULong
    reserver : CULong
  end

  type ZStreamP = ZStream*

  fun version = zlibVersion(): CChar*


  fun inflateInit2_(ZStreamP, windowBits : CInt, version : CChar*, size : CInt) : CInt

  fun inflate(ZStreamP, flush : CInt) : CInt
end
