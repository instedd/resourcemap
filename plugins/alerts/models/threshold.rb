class Threshold < ActiveRecord::Base
  belongs_to :collection

  validates :collection, :presence => true
  validates :ord, :presence => true
  validates :color, :presence => true

  serialize :conditions, Array
  serialize :phone_notification
  serialize :email_notification
  serialize :sites, Array

  before_save :strongly_type_conditions
  def strongly_type_conditions
    fields = collection.fields.index_by(&:es_code)
    self.conditions.each_with_index do |hash, i|
      field = fields[hash[:field]]
      self.conditions[i][:value] = field.strongly_type(hash[:value]) if field
    end
  end

  def test(properties)
    if is_all_condition
      throw :threshold, self if conditions.all? do |hash|
        if value = properties[hash[:field]]
          true if condition(hash, properties).evaluate(value)
        end
      end
    else
      throw :threshold, self if conditions.any? do |hash|
        if value = properties[hash[:field]]
          true if condition(hash, properties).evaluate(value)
        end
      end
    end
  end

  def condition(hash, properties)
    Threshold::Condition.new hash, properties
  end
end
