class Object
  def to_i_or_f
    Integer(self)
  rescue
    Float(self) rescue nil
  end
end
