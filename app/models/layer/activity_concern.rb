module Layer::ActivityConcern
  extend ActiveSupport::Concern

  included do
    after_create :create_created_activity, :unless => :mute_activities
    before_update :record_status_before_update, :unless => :mute_activities
    after_update :create_updated_activity, :unless => :mute_activities
    after_destroy :create_deleted_activity, :unless => :mute_activities, :if => :user
  end

  def create_created_activity
    fields_data = fields.map do |field|
      hash = {'id' => field.id, 'kind' => field.kind, 'code' => field.code, 'name' => field.name}
      hash['config'] = field.config if field.config
      hash
    end
    Activity.create! item_type: 'layer', action: 'created', collection_id: collection.id, layer_id: id, user_id: user.id, 'data' => {'name' => name, 'fields' => fields_data}
  end

  def record_status(record)
    if record.new_record?
      [:added, nil]
    elsif record.marked_for_destruction?
      [:deleted, nil]
    elsif record.changes.any?
      [:changed, record.changes]
    end
  end

  def record_status_before_update
    @name_was = name_was
    @all_fields_with_status = fields.map {|f| [f, record_status(f)] }
  end

  def create_updated_activity
    #Activities when 'anonymous_user_permission' field changed are created in set_layer_access method of anonymous membership class
    return if changes['anonymous_user_permission']

    layer_changes = changes.except('updated_at').to_hash

    layer_field_changes = Hash.new { |h,k| h[k] = [] }
    @all_fields_with_status.each do |field, (status, changes)|
      case status
      when :added
        layer_field_changes['added'] << field_hash(field)
      when :deleted
        layer_field_changes['deleted'] << field_hash(field)
      when :changed
        layer_field_changes['changed'] << field_hash(field).merge(changes)
      end
    end

    layer_changes.merge!(layer_field_changes)

    Activity.create! item_type: 'layer', action: 'changed', collection_id: collection.id, layer_id: id, user_id: user.id, 'data' => {'name' => @name_was || name, 'changes' => layer_changes}
  end

  def create_deleted_activity
    Activity.create! item_type: 'layer', action: 'deleted', collection_id: collection.id, layer_id: id, user_id: user.id, 'data' => {'name' => name}
  end
end
