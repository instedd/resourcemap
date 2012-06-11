class UserSnapshot < ActiveRecord::Base
  belongs_to :snapshot
  belongs_to :user

  before_create :destroy_previous_for_user

  def destroy_previous_for_user
    UserSnapshot.destroy_all user_id: self.user_id
  end

end
