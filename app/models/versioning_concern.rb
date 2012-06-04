module VersioningConcern
  extend ActiveSupport::Concern

  included do
    after_save :create_history
    before_destroy :set_history_expiration
  end

  def create_history
    history_class = "#{self.class.name}History".constantize
    history = history_class.get_current_value self
    if history
      history.set_valid_to self.updated_at
    end
    history_class.create_from_site self
    self.site_histories.insert(history)
  end

  def set_history_expiration
    history_class = "#{self.class.name}History".constantize
    history = history_class.get_current_value self
    history.set_valid_to Time.now
  end
end
