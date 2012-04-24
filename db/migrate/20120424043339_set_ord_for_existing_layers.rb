class SetOrdForExistingLayers < ActiveRecord::Migration
  def up
    Collection.all.each do |collection|
      collection.layers.each_with_index do |layer, i|
        layer.ord = i + 1
        layer.save!
      end
    end
  end

  def down
  end
end
