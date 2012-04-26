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
      "Collection '#{data[:name]}' was created"
    when 'collection_imported'
      "Import wizard: #{groups_and_sites_were_imported_text}"
    when 'collection_csv_imported'
      "Import CSV: #{groups_and_sites_were_imported_text}"
    when 'layer_created'
      fields_str = data[:fields].map { |f| "#{f[:name]} (#{f[:code]})" }.join ', '
      str = "Layer '#{data[:name]}' was created with fields: #{fields_str}"
    when 'site_created'
      "Site '#{data[:name]}' was created"
    when 'group_created'
      "Group '#{data[:name]}' was created"
    end
  end

  private

  def groups_and_sites_were_imported_text
    groups_created_text = "#{data[:groups]} group#{data[:groups] == 1 ? '' : 's'}"
    sites_created_text = "#{data[:sites]} site#{data[:sites] == 1 ? '' : 's'}"
    "#{groups_created_text} and #{sites_created_text} were imported"
  end
end
