module ActiveRecordTelemetry

  extend ActiveSupport::Concern

  def touch_user_lifespan
    Telemetry::Lifespan.touch_user(self.user)
  end

  def touch_collection_lifespan
    Telemetry::Lifespan.touch_collection(self.collection)
  end

  def touch_membership_lifespan
    Telemetry::Lifespan.touch_collection(self.membership.try(:collection))
    Telemetry::Lifespan.touch_user(self.membership.try(:user))
  end

end

ActiveRecord::Base.send(:include, ActiveRecordTelemetry)
