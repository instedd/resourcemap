class AddPropertyNameAndIsAllSiteToThresholds < ActiveRecord::Migration
  def change
    add_column :thresholds, :property_name, :string

    add_column :thresholds, :is_all_site, :boolean

  end
end
