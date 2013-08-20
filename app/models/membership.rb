class Membership < ActiveRecord::Base
  include Membership::ActivityConcern
  include Membership::LayerAccessConcern
  include Membership::SitesPermissionConcern
  # Todo move Default fields behaviour to concern!

  belongs_to :user
  belongs_to :collection
  has_many :layer_memberships, dependent: :destroy
  has_one :read_sites_permission, dependent: :destroy
  has_one :write_sites_permission, dependent: :destroy
  has_one :name_permission, dependent: :destroy
  has_one :location_permission, dependent: :destroy


  validates :user_id, :uniqueness => { scope: :collection_id, message: "membership already exists" }

  #TODO: refactor Name, Location, Site, and Layer permission into membership subclases
  def can_read?(field)
    if field == "name"
      name_permission.can_read?
    elsif field == "location"
      location_permission.can_read?
    else
      raise "Undefined field #{field} for membership."
    end
  end

  #TODO: refactor Name, Location, Site, and Layer permission into membership subclases
  def can_update?(field)
    if field == "name"
      name_permission.can_update?
    elsif field == "location"
      location_permission.can_update?
    else
      raise "Undefined field #{field} for membership."
    end
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

    lm = layer_memberships.where(:layer_id => options[:layer_id]).first
    if lm
      lm.read = read unless read.nil?
      lm.write = write unless write.nil?

      if lm.read || lm.write
        lm.save!
      else
        lm.destroy
      end
    else
      layer_memberships.create! :layer_id => options[:layer_id], :read => read, :write => write
    end
  end
end
