class UpdateColumnIconWithDefaultValue < ActiveRecord::Migration
  def up
    Collection.update_all ["icon=?", "default"] 
  end

  def down
  end
end
