class Threshold < ActiveRecord::Base
  belongs_to :collection
  validates :priority, :presence => true
  validates :color, :presence => true
  
  serialize :conditions, Array

  def test(properties)
    conditions.each do |hash|
      field = hash[:field]
      if properties.has_key? field
        condition(hash).evaluate properties[field]
      end
    end
  end

  def condition(hash)
    Threshold::Condition.new hash
  end
end
