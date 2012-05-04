class Threshold < ActiveRecord::Base
  belongs_to :collection
  validates :priority, :presence => true
  validates :color, :presence => true
  
  serialize :condition, Array

  def test(properties)
    condition.each do |hash|
      field = hash[:field]
      if properties.has_key? field
        _condition(hash).evaluate properties[field]
      end
    end
  end

  def _condition(hash)
    Threshold::Condition.new hash
  end
end
