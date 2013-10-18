class DeleteOrphanElementsInMemberships < ActiveRecord::Migration
  def up
    connection.execute "DELETE `memberships`.*  FROM `memberships` WHERE NOT EXISTS( select `collections`.`id` from `collections`  where `collections`.`id` = `memberships`.`collection_id` )"
  end

  def down
  end
end
