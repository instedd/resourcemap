class AddIndexes < ActiveRecord::Migration
  def change
    add_index(:fields, :layer_id)
    add_index(:fields, :collection_id)

    add_index(:layers, :collection_id)

    add_index(:memberships, :user_id)

    add_index(:memberships, :collection_id)

    add_index(:sites, :collection_id)
  end
end
