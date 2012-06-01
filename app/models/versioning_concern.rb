module VersioningConcern

  def create_history(history_class, object)
    history = history_class.get_current_value object
    if history
      history.set_valid_to object.updated_at
    end
    history_class.create_from_site object
  end

  def set_history_expiration(history_class, object)
    history = history_class.get_current_value object
    history.set_valid_to Time.now
  end
end
