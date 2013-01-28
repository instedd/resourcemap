class Membership < ActiveRecord::Base
  include Membership::ActivityConcern
  include Membership::LayerAccessConcern
  include Membership::SitesPermissionConcern

  belongs_to :user
  belongs_to :collection
  has_one :read_sites_permission, dependent: :destroy
  has_one :write_sites_permission, dependent: :destroy

  before_destroy :destroy_collection_memberships
  def destroy_collection_memberships
    collection.layer_memberships.where(:user_id => user_id).destroy_all
  end

  def set_layer_access(options = {})
    intent = options[:verb].to_s

    read = nil
    write = nil

    if intent == 'read'
      read = options[:access]
      # If the intent is to set read permissions, we assume write permissions have to be denied.
      write = false
    elsif intent == 'write'
      write = options[:access]
      # Write permissions imply read permissions.
      read = true if write
    end

    lm = collection.layer_memberships.where(:layer_id => options[:layer_id], :user_id => user_id).first
    if lm
      lm.read = read unless read.nil?
      lm.write = write unless write.nil?

      if lm.read || lm.write
        lm.save!
      else
        lm.destroy
      end
    else
      collection.layer_memberships.create! :layer_id => options[:layer_id], :user_id => user_id, :read => read, :write => write
    end
  end
end
