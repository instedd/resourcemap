class AddUserIdCulumnToChannel < ActiveRecord::Migration
  def change
    add_column :channels, :user_id, :integer
  end
end
