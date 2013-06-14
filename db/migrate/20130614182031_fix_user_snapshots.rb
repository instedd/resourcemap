class FixUserSnapshots < ActiveRecord::Migration
  def up
    UserSnapshot.find_each do |user_snapshot|
      # To yield the migration against future changes in UserSnapshot's interface
      return unless user_snapshot.respond_to?(:collection_id) && user_snapshot.respond_to?(:snapshot_id) && user_snapshot.respond_to?(:snapshot)

      if !user_snapshot.snapshot_id.nil? && user_snapshot.collection_id.nil?
        return unless user_snapshot.snapshot.respond_to?(:collection_id)
        user_snapshot.collection_id = user_snapshot.snapshot.collection_id
        user_snapshot.save!
      end
    end
  end

  def down
  end
end
