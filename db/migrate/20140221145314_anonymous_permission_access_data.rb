class AnonymousPermissionAccessData < ActiveRecord::Migration
  class Collection < ActiveRecord::Base
    has_many :layers
  end

  class Layer < ActiveRecord::Base
    belongs_to :collection
  end

  def up
    Layer.transaction do
      Collection.includes(:layers).where(:public => true).find_each do |c|
        c.layers.each do |l|
          l.anonymous_user_permission = "read"
          l.save!
        end
      end
    end
  end

  def down
    Layer.find_each do |l|
      l.anonymous_user_permission = "none"
      l.save!
    end
  end
end
