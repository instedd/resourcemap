class Threshold::Condition
  include Threshold::ComparisonConcern

  attr_accessor :operator, :value

  def initialize(hash)
    @operator = hash[:op]
    @value = hash[:value]
  end

  def evaluate(value)
    send @operator, value, @value
  end
end
