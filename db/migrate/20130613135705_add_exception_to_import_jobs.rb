class AddExceptionToImportJobs < ActiveRecord::Migration
  def change
    add_column :import_jobs, :exception, :text
  end
end
