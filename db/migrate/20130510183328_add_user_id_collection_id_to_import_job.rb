class AddUserIdCollectionIdToImportJob < ActiveRecord::Migration
  def change
    add_column :import_jobs, :user_id, :integer
    add_column :import_jobs, :collection_id, :integer
  end
end
