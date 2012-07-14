class SetOrdForExistingFields < ActiveRecord::Migration
  def up
    c = ActiveRecord::Base.connection
    c.execute("select id from collections").each do |collection_id|
      c.execute("select id from layers where collection_id = #{collection_id[0]}").each do |layer_id|
        c.execute("select id from fields where layer_id = #{layer_id[0]} order by id").each_with_index do |field_id, i|
          c.execute("update fields set ord = #{i + 1} where id = #{field_id[0]}")
        end
      end
    end
  end

  def down
  end
end
