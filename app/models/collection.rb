class Collection < ActiveRecord::Base
  include Collection::CsvConcern
  include Collection::GeomConcern
  include Collection::TireConcern

  validates_presence_of :name

  has_many :memberships
  has_many :users, through: :memberships
  has_many :sites, dependent: :delete_all
  has_many :root_sites, class_name: 'Site', conditions: {parent_id: nil}
  has_many :layers, dependent: :destroy
  has_many :fields

  def max_value_of_property(property)
    search = new_tire_search
    search.sort { by property, 'desc' }
    search.size 1
    search.perform.results.first['_source']['properties'][property] rescue 0
  end
end
