struct Int
  def to_culong
    ifdef x86_64
      to_u64
    else
      to_u32
    end
  end
end
