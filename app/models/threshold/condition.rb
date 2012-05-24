class Threshold::Condition
  include Threshold::ComparisonConcern

  attr_accessor :field, :operator, :value

  def initialize(hash)
    @operator = hash[:is]
    @value = hash[:value]
  end

  def evaluate(value)
    send @operator, value, @value
  end
end
