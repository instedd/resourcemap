class String
  # Does this string represent an integer?
  def integer?
    Integer(self) rescue nil
  end
end
