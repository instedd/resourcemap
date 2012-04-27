class Layer < ActiveRecord::Base
  include Activity::AwareConcern

  belongs_to :collection
  has_many :fields, order: 'ord', dependent: :destroy

  accepts_nested_attributes_for :fields, :allow_destroy => true

  validates_presence_of :ord

  after_create :update_collection_mapping
  def update_collection_mapping
    collection.update_mapping
  end

  before_update :before_rename_site_properties_if_fields_code_changed
  def before_rename_site_properties_if_fields_code_changed
    @fields_renames = Hash[fields.select(&:code_changed?).reject{|f| f.code_was.nil? || f.code.nil?}.map{|f| [f.code_was, f.code]}]
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

  # I'd move this code to a concern, but it works differntly (the fields don't
  # have an id). Must probably be a bug in Active Record.
  after_create :create_created_activity, :unless => :mute_activities
  def create_created_activity
    fields_data = fields.map do |field|
      hash = {id: field.id, kind: field.kind, code: field.code, name: field.name}
      hash[:config] = field.config if field.config
      hash
    end
    Activity.create! kind: 'layer_created', collection_id: collection.id, layer_id: id, user_id: user.id, data: {name: name, fields: fields_data}
  end

  before_update :record_status_before_update, :unless => :mute_activities
  def record_status_before_update
    @name_was = name_was
    @before_update_fields = fields.all
    @before_update_changes = changes.dup
  end

  after_update :create_updated_activity, :unless => :mute_activities
  def create_updated_activity
    layer_changes = changes.except 'updated_at'

    after_update_fields = fields.all

    added = []
    deleted = []

    after_update_fields.each do |new_field|
      old_field = @before_update_fields.find { |f| f.id == new_field.id }
      unless old_field
        field_hash = {id: new_field.id, code: new_field.code, name: new_field.name, kind: new_field.kind}
        field_hash[:config] = new_field.config if new_field.config.present?
        added.push field_hash
      end
    end

    @before_update_fields.each do |old_field|
      new_field = after_update_fields.find { |f| f.id == old_field.id }
      unless new_field
        field_hash = {id: old_field.id, code: old_field.code, name: old_field.name, kind: old_field.kind}
        field_hash[:config] = old_field.config if old_field.config.present?
        deleted.push field_hash
      end
    end

    layer_changes[:added] = added if added.present?
    layer_changes[:deleted] = deleted if deleted.present?

    Activity.create! kind: 'layer_changed', collection_id: collection.id, layer_id: id, user_id: user.id, data: {name: @name_was || name, changes: layer_changes}
  end

  after_destroy :create_deleted_activity, :unless => :mute_activities
  def create_deleted_activity
    Activity.create! kind: 'layer_deleted', collection_id: collection.id, layer_id: id, user_id: user.id, data: {name: name}
  end

  # Returns the next ord value for a field that is going to be created
  def next_field_ord
    field = fields.select('max(ord) as o').first
    field ? field['o'].to_i + 1 : 1
  end
end
