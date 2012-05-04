class Threshold::Condition
  include Threshold::ComparisonConcern

  attr_accessor :field, :operator, :value
  
  def initialize(hash)
    @operator = hash[:is]
    @value = hash[:value]
  end

  def evaluate(value)
    throw :threshold, true if __send__(@operator, value, @value)
  end
end
