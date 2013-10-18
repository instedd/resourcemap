class AddUserToSiteHistory < ActiveRecord::Migration
  def change
    add_column :site_histories, :user_id, :integer
  end
end
