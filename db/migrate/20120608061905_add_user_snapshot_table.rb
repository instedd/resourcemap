class AddUserSnapshotTable < ActiveRecord::Migration
  def change
    create_table :user_snapshots do |t|
      t.references :user
      t.references :snapshot

      t.timestamps
    end
  end
end
