class SetOrdForExistingLayers < ActiveRecord::Migration
  def up
    c = ActiveRecord::Base.connection
    c.execute("select id from collections").each do |collection_id|
      c.execute("select id from layers where collection_id = #{collection_id[0]} order by id").each_with_index do |layer_id, i|
        c.execute("update layers set ord = #{i + 1} where id = #{layer_id[0]}")
      end
    end
  end

  def down
  end
end
