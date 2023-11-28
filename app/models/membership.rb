class Membership < ApplicationRecord
  include Membership::ActivityConcern
  include Membership::SitesPermissionConcern
  include Membership::DefaultPermissionConcern

  belongs_to :user
  belongs_to :collection
  has_many :layer_memberships, dependent: :destroy
  has_one :read_sites_permission, dependent: :destroy
  has_one :write_sites_permission, dependent: :destroy
  has_one :name_permission, dependent: :destroy
  has_one :location_permission, dependent: :destroy

  validates :user_id, :uniqueness => { scope: :collection_id, message: "membership already exists" }

  after_save :touch_collection_lifespan
  after_destroy :touch_collection_lifespan
  after_save :touch_user_lifespan
  after_destroy :touch_user_lifespan

  def assign_attributes(new_attributes)
    super ActiveSupport::HashWithIndifferentAccess.new(new_attributes).slice(
      :collection_id,
      :admin,
      :user_id,
      :collection,
      :user
    )
  end

  #TODO: refactor Name, Location, Site, and Layer permission into membership subclases
  def can_read?(object)
    if admin
      true
    elsif object == "name"
      name_permission.can_read?
    elsif object == "location"
      location_permission.can_read?
    else
      raise "Undefined element #{object} for membership."
    end
  end

  #TODO: refactor Name, Location, Site, and Layer permission into membership subclases
  def can_update?(object)
    if admin
      true
    elsif object == "name"
      name_permission.can_update?
    elsif object == "location"
      location_permission.can_update?
    else
      raise "Undefined element #{object} for membership."
    end
  end

  def set_access(options = {})
    object = options[:object]
    if object == 'name'
      name_permission.activity_user = activity_user
      name_permission.set_access(options[:new_action])
    elsif object == 'location'
      location_permission.activity_user = activity_user
      location_permission.set_access(options[:new_action])
    else
      raise "Undefined element #{object} for membership."
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
      lm.activity_user = activity_user
      lm.read = read unless read.nil?
      lm.write = write unless write.nil?

      if lm.read || lm.write
        lm.save!
      else
        lm.destroy
      end
    else
      new_lm = layer_memberships.new :layer_id => options[:layer_id], :read => read, :write => write
      new_lm.activity_user = activity_user
      new_lm.save!
    end
  end

  def as_json(options = {})
    {
      user_id: user_id,
      user_display_name: user.display_name,
      admin: admin?,
      layers: layer_memberships.map{|x| {layer_id: x.layer_id, read: x.read?, write: x.write?}},
      sites: {
        read: read_sites_permission,
        write: write_sites_permission
      },
      name: action_for_name_permission,
      location: action_for_location_permission,
    }
  end

  def self.check_and_create(email, collection_id)
    user = User.find_by_email email
    if !user
      [:missing_user]
    elsif user.memberships.where(:collection_id => collection_id).exists?
      [:membership_exists, user.memberships.where(:collection_id => collection_id), user]
    else
      membership = user.memberships.create! :collection_id => collection_id
      [:added, membership, user]
    end
  end

  def change_admin_flag(new_value)
    self.admin = new_value
    self.save!
    create_activity_when_admin_permission_changes
  end

end
