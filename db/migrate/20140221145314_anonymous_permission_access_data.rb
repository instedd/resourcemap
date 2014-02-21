class AnonymousPermissionAccessData < ActiveRecord::Migration
  class Collection < ActiveRecord::Base
    has_many :layers
  end

  class Layer < ActiveRecord::Base
    belongs_to :collection
  end

  def up
    Layer.find_each do |l|
      l.anonymous_user_permission = l.collection.public ? "read" : "none"
      l.save!
    end
  end

  def down
    Layer.find_each do |l|
      l.anonymous_user_permission = "none"
      l.save!
    end
  end
end
