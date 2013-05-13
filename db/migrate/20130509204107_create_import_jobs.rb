class CreateImportJobs < ActiveRecord::Migration
  def change
    create_table :import_jobs do |t|
      t.string :status
      t.string :original_filename
      t.datetime :finished_at

      t.timestamps
    end
  end
end
