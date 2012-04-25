class Activity < ActiveRecord::Base
  belongs_to :collection
  belongs_to :user
  belongs_to :layer
  belongs_to :field
  belongs_to :site

  def description
    case kind
    when 'collection_created'
      'Collection was created'
    end
  end
end
