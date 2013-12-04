Oj.default_options = {mode: :compat}

class Object
  def to_json_oj
    Oj.dump self
  end
end
