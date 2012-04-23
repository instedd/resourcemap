class Layer < ActiveRecord::Base
  belongs_to :collection
  has_many :fields, dependent: :destroy

  accepts_nested_attributes_for :fields

  # After we create/update a layer, if there are new fields in it
  # and we try to sort/search by them, Elastic Search breaks
  # (it says: no mapping found for field ...)
  # To fix that we create a new site in the collection,
  # set its properties to something non-empty, save it and then
  # destroy it.
  after_save :create_mapping_for_new_fields
  def create_mapping_for_new_fields
    site = collection.sites.new name: 'Dummy', group: false
    fields.each do |field|
      site.properties[field.code] = field.non_empty_value
    end
    site.save!

    site.destroy
  end
end
