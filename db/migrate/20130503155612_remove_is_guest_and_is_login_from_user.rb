class RemoveIsGuestAndIsLoginFromUser < ActiveRecord::Migration
  def up
    remove_column :users, :is_guest
    remove_column :users, :is_login
  end

  def down
    add_column :users, :is_login, :boolean
    add_column :users, :is_guest, :boolean
  end
end
