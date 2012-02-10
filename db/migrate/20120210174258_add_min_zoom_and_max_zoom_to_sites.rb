class AddMinZoomAndMaxZoomToSites < ActiveRecord::Migration
  def change
    add_column :sites, :min_zoom, :integer

    add_column :sites, :max_zoom, :integer

  end
end
