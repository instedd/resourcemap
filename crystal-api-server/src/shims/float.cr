struct Float64
  def to_s(io : IO)
    if self == self.trunc
      chars = StaticArray(UInt8, 50).new(0_u8)
      LibC.snprintf(chars, 50, "%0.f", self)
      io.write(chars.to_slice, LibC.strlen(chars.buffer))
    else
      # previous_def
      chars = StaticArray(UInt8, 22).new(0_u8)
      LibC.snprintf(chars, 22, "%0.5f", self)
      io.write(chars.to_slice, LibC.strlen(chars.buffer))
    end
  end
end
