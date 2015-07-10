struct JSON::ArrayBuilder(T)
  def append
    if @count > 0
      @io << ","
      @io << '\n' if @indent > 0
    end
    @indent.times { @io << "  " }
    yield
    @count += 1
  end
end
