class ChangeFieldConfigToBinary < ActiveRecord::Migration
  def up
    change_column :fields, :config, :binary, limit: 2147483647
  end

  def down
    change_column :fields, :config, :text
  end
end
