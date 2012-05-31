class CreateSiteHistory < ActiveRecord::Migration
  def up
    execute <<-SQL
      CREATE TABLE site_histories LIKE sites;
    SQL
    add_column :site_histories, :valid_since, :datetime
    add_column :site_histories, :valid_to, :datetime
    add_column :site_histories, :site_id, :integer
    add_index :site_histories, :site_id
  end

  def down
    drop_table :site_histories
  end
end
