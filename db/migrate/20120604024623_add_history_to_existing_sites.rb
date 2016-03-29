class AddHistoryToExistingSites < ActiveRecord::Migration
  def up
    Site.unscoped.find_each do |site|
      site.create_history unless site.current_history
    end
  end

  def down
  end
end
