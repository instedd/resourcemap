class SetOrdForExistingLayers < ActiveRecord::Migration
  def up
    Collection.order('id').includes(:layers).all.each do |collection|
      collection.layers.order('id').each_with_index do |layer, i|
        layer.ord = i + 1
        layer.save!
      end
    end
  end

  def down
  end
end
