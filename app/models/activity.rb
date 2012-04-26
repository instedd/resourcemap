class Activity < ActiveRecord::Base
  belongs_to :collection
  belongs_to :user
  belongs_to :layer
  belongs_to :field
  belongs_to :site

  serialize :data

  def description
    case kind
    when 'collection_created'
      'Collection was created'
    when 'collection_imported'
      groups_created_text = "#{data[:groups]} group#{data[:groups] == 1 ? '' : 's'}"
      sites_created_text = "#{data[:sites]} site#{data[:sites] == 1 ? '' : 's'}"
      "Import wizard: #{groups_created_text} and #{sites_created_text} were imported"
    when 'layer_created'
      'Layer was created'
    end
  end
end
