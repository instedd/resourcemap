class UserSnapshot < ActiveRecord::Base
  belongs_to :snapshot
  belongs_to :user
  belongs_to :collection

  before_create :destroy_previous_for_user_and_collection

  def destroy_previous_for_user_and_collection
    UserSnapshot.destroy_all user_id: self.user_id, collection_id: self.collection_id
  end

  def go_back_to_present!
    self.snapshot_id = nil
    self.save! unless self.new_record?
  end

  # Loads the given collection snapshot for the related user.
  # Returns false if there's no such a snapshot.
  # Returns true if it succeeds.
  def go_to!(snapshot_name)
    snapshot_to_load = collection.snapshots.where(:name => snapshot_name).first

    return false unless snapshot_to_load

    self.snapshot_id = snapshot_to_load.id
    self.save!

    true
  end

  def at_present?
    self.snapshot_id.nil?
  end

  def self.for(user, collection)
    user_snapshot = UserSnapshot.where(user_id: user.id, collection_id: collection.id).first
    user_snapshot ||= UserSnapshot.new user: user, collection: collection
    user_snapshot
  end
end
