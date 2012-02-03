class Site < ActiveRecord::Base
  belongs_to :collection
  belongs_to :parent, :foreign_key => 'parent_id', :class_name => name

  has_many :sites, :foreign_key => 'parent_id'

  serialize :properties, Hash

  def as_json(options = {})
    json = {}
    json[:id] = id if id
    json[:name] = name if name
    json[:lat] = lat if lat
    json[:lng] = lng if lng
    json[:folder] = folder if folder
    json[:parent_id] = parent_id if parent_id
    json[:properties] = properties if properties.present?
    json
  end
end
