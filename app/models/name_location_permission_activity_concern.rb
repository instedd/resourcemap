module NameLocationPermissionActivityConcern
  extend ActiveSupport::Concern

  included do
    attr_accessor :activity_user
  end

end
