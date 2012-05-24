class Threshold < ActiveRecord::Base
  belongs_to :collection

  validates :collection, :presence => true
  validates :ord, :presence => true
  validates :color, :presence => true

  serialize :conditions, Array

  def test(properties)
    throw :threshold, true if conditions.all? do |hash|
      if property = properties[field = hash[:field]]
        true if condition(hash).evaluate(property)
      end
    end
  end

  def condition(hash)
    Threshold::Condition.new hash
  end
end
