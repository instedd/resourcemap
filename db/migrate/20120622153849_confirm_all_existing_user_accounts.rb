class ConfirmAllExistingUserAccounts < ActiveRecord::Migration
  def up
     User.update_all ["confirmed_at = ?", Time.now]
  end

  def down
  end
end
