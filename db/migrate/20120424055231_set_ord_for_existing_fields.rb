class SetOrdForExistingFields < ActiveRecord::Migration
  def up
    Collection.includes(:layers => :fields).each do |collection|
      collection.layers.each do |layer|
        layer.fields.each_with_index do |field, i|
          field.ord = i + 1
          field.save!
        end
      end
    end
  end

  def down
  end
end
