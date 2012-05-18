class Site < ActiveRecord::Base
  include Activity::AwareConcern
  include Site::ActivityConcern
  include Site::GeomConcern
  include Site::TireConcern

  belongs_to :collection

  serialize :properties, Hash

  before_save :strongly_type_properties
  def strongly_type_properties
    fields = collection.fields.index_by(&:es_code)
    self.properties.keys.each do |key|
      field = fields[key]
      self.properties[key] = properties[key].to_i_or_f if field && field.stored_as_number?
      self.properties[key].map!(&:to_i) if field && field.kind == 'select_many'
    end
  end

  before_save :remove_nil_properties, :if => :properties
  def remove_nil_properties
    self.properties.reject! { |k, v| v.nil? }
  end

  def human_properties
    fields = collection.fields.index_by(&:es_code)

    props = {}
    properties.each do |key, value|
      field = fields[key]
      if field
        if field.kind == 'select_one'
          option = field.config['options'].find { |o| o['id'] == value }
          props[field.name] = option ? option['label'] : value
        elsif field.kind == 'select_many'
          if value.is_a? Array
            props[field.name] = value.map do |val|
              option = field.config['options'].find { |o| o['id'] == val }
              option ? option['label'] : val
            end
          else
            props[field.name] = value
          end
        elsif field.kind == 'hierarchy'
          props[field.name] = value
        else
          props[field.name] = value
        end
      else
        props[key] = value
      end
    end
    props
  end
end
