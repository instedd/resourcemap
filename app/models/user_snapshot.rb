class UserSnapshot < ActiveRecord::Base
  belongs_to :snapshot
  belongs_to :user

  before_create :destroy_previous_for_user

  def destroy_previous_for_user
    UserSnapshot.destroy_all user_id: self.user_id
  end

  def self.get_for(user, collection)
    self.joins(:snapshot).where user_id: user.id, :snapshots => { :collection_id => collection.id}
  end

end
