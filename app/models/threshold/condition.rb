class Threshold::Condition
  include Threshold::ComparisonConcern

  attr_accessor :operator, :value

  def initialize(hash, properties)
    @operator = hash[:op]
    hash[:value] = hash[:value] * properties[hash[:compare_field]] / 100 if hash[:type] == "percentage" 
    @value = hash[:value]
  end

  def evaluate(value)
    send @operator, value, @value
  end
end
