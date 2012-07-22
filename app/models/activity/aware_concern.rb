module Activity::AwareConcern
  extend ActiveSupport::Concern

  included do
    # The user that creates/makes changes to this object
    attr_accessor :user

    # Set to true to stop creating Activities for this object
    attr_accessor :mute_activities

    validates_presence_of :user, :if => :new_record?, :unless => :mute_activities
  end
end
