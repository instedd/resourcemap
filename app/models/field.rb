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

  # Returns the label for the given option code.
  # Returns the same code if the option is not found or this is not a
  # select_one or select_many field.
  def option_label(code)
    if config && config['options']
      config['options'].each do |option|
        return option['label'] if option['code'] == code
      end
    end

    return code
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

  private

  def sanitize_hierarchy_items(items)
    items.map! &:to_hash
    items.each do |item|
      sanitize_hierarchy_items item['sub'] if item['sub']
    end
  end
end
