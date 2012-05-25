class Field < ActiveRecord::Base
  Kinds = %w(text numeric select_one select_many hierarchy)

  include Field::TireConcern

  belongs_to :collection
  belongs_to :layer

  validates_presence_of :ord
  validates_inclusion_of :kind, :in => Kinds

  serialize :config

  before_save :set_collection_id_to_layer_id
  def set_collection_id_to_layer_id
    self.collection_id = layer.collection_id if layer
  end

  before_save :save_config_as_hash_not_with_indifferent_access, :if => :config?
  def save_config_as_hash_not_with_indifferent_access
    self.config = config.to_hash

    self.config['options'].map!(&:to_hash) if self.config['options']
    sanitize_hierarchy_items self.config['hierarchy'] if self.config['hierarchy']
  end

  Kinds.each do |kind|
    class_eval %Q(def #{kind}?; kind == '#{kind}'; end)
  end

  def select_kind?
    select_one? || select_many?
  end

  def stored_as_number?
    numeric? || select_one?
  end

  def strongly_type(value)
    if stored_as_number?
      value.to_i_or_f
    elsif select_many?
      value.map &:to_i
    else
      value
    end
  end

  def api_value(value)
    if select_one?
      option = config['options'].find { |o| o['id'] == value }
      return option ? option['code'] : value
    elsif select_many?
      if value.is_a? Array
        return value.map do |val|
          option = config['options'].find { |o| o['id'] == val }
          option ? option['code'] : val
        end
      else
        return value
      end
    elsif hierarchy?
      return value
    else
      return value
    end
  end

  def human_value(value)
    if select_one?
      option = config['options'].find { |o| o['id'] == value }
      return option ? option['label'] : value
    elsif select_many?
      if value.is_a? Array
        return value.map do |val|
          option = config['options'].find { |o| o['id'] == val }
          option ? option['label'] : val
        end.join ', '
      else
        return value
      end
    elsif hierarchy?
      return find_hierarchy_value value
    else
      return value
    end
  end

  private

  def find_hierarchy_value(value)
    @hierarchy_items_map ||= create_hierarchy_items_map
    item = @hierarchy_items_map[value]
    item ? hierarchy_item_to_s(item) : value
  end

  def create_hierarchy_items_map(map = {}, items = config['hierarchy'], parent = nil)
    items.each do |item|
      map_item = {'name' => item['name'], 'parent' => parent}
      map[item['id']] = map_item
      create_hierarchy_items_map map, item['sub'], map_item if item['sub'].present?
    end
    map
  end

  def hierarchy_item_to_s(str = '', item)
    if item['parent']
      hierarchy_item_to_s str, item['parent']
      str << ' - '
    end
    str << item['name']
    str
  end

  def sanitize_hierarchy_items(items)
    items.map! &:to_hash
    items.each do |item|
      sanitize_hierarchy_items item['sub'] if item['sub']
    end
  end
end
