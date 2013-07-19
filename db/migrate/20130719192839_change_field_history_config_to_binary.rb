class ChangeFieldHistoryConfigToBinary < ActiveRecord::Migration
  def up
    change_column :field_histories, :config, :binary, limit: 2147483647
  end

  def down
    change_column :field_histories, :config, :text
  end
end
