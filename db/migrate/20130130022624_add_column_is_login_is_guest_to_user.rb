class AddColumnIsLoginIsGuestToUser < ActiveRecord::Migration
  def change
    add_column :users, :is_login, :boolean
    add_column :users, :is_guest, :boolean
  end
end
