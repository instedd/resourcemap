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

  def record_status_before_update
    @name_was = name_was
    @before_update_fields = fields.all
    @before_update_changes = changes.dup
  end

  def create_updated_activity
    #Activities when 'anonymous_user_permission' field changed are created in set_layer_access method of anonymous membership class
    return if changes['anonymous_user_permission']

    layer_changes = changes.except('updated_at').to_hash

    after_update_fields = fields.all

    added = []
    changed = []
    deleted = []

    after_update_fields.each do |new_field|
      old_field = @before_update_fields.find { |f| f.id == new_field.id }
      if old_field
        hash = field_hash(new_field)
        really_changed = false

        ['name', 'code', 'kind', 'config'].each do |key|
          if old_field[key] != new_field[key]
            really_changed = true
            hash[key] = [old_field[key], new_field[key]]
          end
        end
        changed.push hash if really_changed
      else
        added.push field_hash(new_field)
      end
    end

    @before_update_fields.each do |old_field|
      new_field = after_update_fields.find { |f| f.id == old_field.id }
      deleted.push field_hash(old_field) unless new_field
    end

    layer_changes['added'] = added if added.present?
    layer_changes['changed'] = changed if changed.present?
    layer_changes['deleted'] = deleted if deleted.present?

    Activity.create! item_type: 'layer', action: 'changed', collection_id: collection.id, layer_id: id, user_id: user.id, 'data' => {'name' => @name_was || name, 'changes' => layer_changes}
  end

  def create_deleted_activity
    Activity.create! item_type: 'layer', action: 'deleted', collection_id: collection.id, layer_id: id, user_id: user.id, 'data' => {'name' => name}
  end
end
