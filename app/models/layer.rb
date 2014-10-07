class Layer < ActiveRecord::Base
  include Activity::AwareConcern
  include HistoryConcern


  belongs_to :collection
  has_many :fields, order: 'ord', dependent: :destroy
  has_many :field_histories, order: 'ord', dependent: :destroy
  has_many :layer_memberships, dependent: :destroy

  accepts_nested_attributes_for :fields, :allow_destroy => true

  validates_presence_of :ord

  # This include needs to be after the has_many :fields declaration
  include Layer::ActivityConcern

  def history_concern_foreign_key
    self.class.name.foreign_key
  end

  # Returns the next ord value for a field that is going to be created
  def next_field_ord
    # field = fields.pluck('max(ord) as o').first
    field = fields.order(:ord).last.try(:ord)
    field ? field.to_i + 1 : 1
  end

  # Instead of sending the _destroy flag to destroy fields (complicates things on the client side code)
  # we check which are the current fields ids, which are the new ones and we delete those fields
  # whose ids don't show up in the new ones and then we add the _destroy flag.
  #
  # That way we preserve existing fields and we can know if their codes change, to trigger a reindex
  def fix_layer_fields_for_update(params)
    fields_ids = fields.map(&:id).compact
    new_ids = params.values.map { |x| x[:id].try(:to_i) }.compact
    removed_fields_ids = fields_ids - new_ids

    max_key = params.keys.map(&:to_i).max
    max_key += 1

    removed_fields_ids.each do |id|
      params[max_key.to_s] = {id: id, _destroy: true}
      max_key += 1
    end

    params.values
  end

  private

  def field_hash(field)
    field_hash = {'id' => field.id, 'code' => field.code, 'name' => field.name, 'kind' => field.kind}
    field_hash['config'] = field.config if field.config.present?
    field_hash
  end
end
