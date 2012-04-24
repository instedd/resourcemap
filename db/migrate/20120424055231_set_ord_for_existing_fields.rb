class SetOrdForExistingFields < ActiveRecord::Migration
  def up
    Collection.order('id').includes(:layers => :fields).each do |collection|
      collection.layers.order('id').each do |layer|
        layer.fields.order('id').each_with_index do |field, i|
          field.ord = i + 1
          field.save!
        end
      end
    end
  end

  def down
  end
end
