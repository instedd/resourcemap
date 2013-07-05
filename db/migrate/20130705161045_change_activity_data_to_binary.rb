class ChangeActivityDataToBinary < ActiveRecord::Migration
  def up
    change_column :activities, :data, :binary, limit: 2147483647
  end

  def down
    change_column :activities, :data, :text
  end
end
