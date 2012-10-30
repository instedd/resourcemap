class Field < ActiveRecord::Base
  include Field::Base
  include Field::TireConcern
  include HistoryConcern

  belongs_to :collection
  belongs_to :layer

  validates_presence_of :ord
  validates_inclusion_of :kind, :in => Kinds
  validates_presence_of :code
  validates_exclusion_of :code, :in => ['lat', 'long', 'name', 'resmap-id', 'last updated']


  serialize :config

  before_save :set_collection_id_to_layer_id, :unless => :collection_id?
  def set_collection_id_to_layer_id
    self.collection_id = layer.collection_id if layer
  end

  before_save :save_config_as_hash_not_with_indifferent_access, :if => :config?
  def save_config_as_hash_not_with_indifferent_access
    self.config = config.to_hash

    self.config['options'].map!(&:to_hash) if self.config['options']
    sanitize_hierarchy_items self.config['hierarchy'] if self.config['hierarchy']
  end

  after_create :update_collection_mapping
  def update_collection_mapping
    collection.update_mapping
  end

  def hierarchy_options_codes
    hierarchy_options.map {|option| option[:id]}
  end

  def hierarchy_options
    options = []
    config['hierarchy'].each do |option|
      add_option_to_options(options, option)
    end
    options
  end

  def find_hierarchy_id_by_name(value)
    option = hierarchy_options.find {|opt| opt[:name] == value}
    option[:id] if option
  end

  private

  def add_option_to_options(options, option)
    options << { id: option['id'], name: option['name']}
    if option['sub']
      option['sub'].each do |sub_option|
        add_option_to_options(options, sub_option)
      end
    end
  end

  def sanitize_hierarchy_items(items)
    items.map! &:to_hash
    items.each do |item|
      sanitize_hierarchy_items item['sub'] if item['sub']
    end
  end
end
