class Layer < ActiveRecord::Base
  belongs_to :collection
  has_many :fields, order: 'ord', dependent: :destroy

  accepts_nested_attributes_for :fields

  validates_presence_of :ord

  # The user that creates/makes changes to this layer
  attr_accessor :user

  # Set to true to stop creating Activities for this layer
  attr_accessor :mute_activities

  validates_presence_of :user, :if => :new_record?, :unless => :mute_activities

  after_create :update_collection_mapping
  def update_collection_mapping
    collection.update_mapping
  end

  before_update :before_rename_site_properties_if_fields_code_changed
  def before_rename_site_properties_if_fields_code_changed
    @fields_renames = Hash[fields.select(&:code_changed?).map{|f| [f.code_was, f.code]}]
  end

  after_update :rename_site_properties_if_fields_code_changed
  def rename_site_properties_if_fields_code_changed
    collection.update_mapping

    fields_renames_values = @fields_renames.values

    if @fields_renames.present?
      collection.sites.each do |site|

        # Optimization: setting the parent here avoids querying it when indexing
        site.collection = collection

        originals = site.properties.slice *@fields_renames.keys

        @fields_renames.each do |from, to|
          site.properties.delete from unless fields_renames_values.include? from
          site.properties[to] = originals[from]
        end
        site.record_timestamps = false
        site.save!
      end
      @fields_renames = nil
    end
  end

  after_create :create_activity, :unless => :mute_activities
  def create_activity
    Activity.create! kind: 'layer_created', collection_id: collection.id, layer_id: id, user_id: user.id
  end

  # Returns the next ord value for a field that is going to be created
  def next_field_ord
    field = fields.select('max(ord) as o').first
    field ? field['o'].to_i + 1 : 1
  end
end
