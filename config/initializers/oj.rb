Oj.default_options = {mode: :compat, bigdecimal_load: :float }

class Object
  def to_json_oj
    Oj.dump self
  end
end

MultiJson.use :oj
