class AddSuccessOutcomeToUser < ActiveRecord::Migration
  def change
    add_column :users, :success_outcome, :boolean
  end
end
