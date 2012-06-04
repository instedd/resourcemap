module VersioningConcern
  extend ActiveSupport::Concern

  included do
    after_save :create_history
    before_destroy :set_history_expiration
  end

  def relationship_prop(object)
    "#{self.class.name.underscore}_id"
  end

  def history_class(object)
    "#{object.class.name}History".constantize
  end

  def create_from(object)
    history_class = history_class(object)
    history = history_class.new
    object.attributes.each_pair do |att_name, att_value|
      if(!(['id', 'created_at', 'updated_at'].include? att_name))
        history[att_name] = att_value
      end
    end
    history["valid_since"] = self.updated_at
    history[relationship_prop self] = object.id
    history.save
    history
  end

  def get_current_value(object)
    history_class(object).first(:conditions => "#{relationship_prop self} = #{object.id} AND valid_to IS NULL")
  end

  def create_history
    history = get_current_value self
    if history
      history.valid_to = self.updated_at
      history.save
    end
    create_from self
  end

  def set_history_expiration
    history = get_current_value self
    history.valid_to = Time.now
    history.save
  end
end
