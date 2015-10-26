module Telemetry::Lifespan
  def self.touch_collection(collection)
    if collection.present?
      InsteddTelemetry.timespan_update('collection_lifespan', {collection_id: collection.id}, collection.created_at, Time.now.utc)

      collection.users.each do |user|
        self.touch_user(user)
      end
    end
  end

  def self.touch_user(user)
    InsteddTelemetry.timespan_update('account_lifespan', {account_id: user.id}, user.created_at, Time.now.utc) if user.present?
  end
end
