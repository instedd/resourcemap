class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable,
         :token_authenticatable, :omniauthable
  before_create :reset_authentication_token
  # Setup accessible (or protected) attributes for your model attr_accessible :email, :password, :password_confirmation, :remember_me, :phone_number
  has_many :memberships
  has_many :channels
  has_many :collections, through: :memberships, order: 'collections.name ASC'
  has_one :user_snapshot
  has_many :identities, dependent: :destroy

  attr_accessor :is_guest

  # In order to use it in the ability file
  # this loads accessible layers for ALL the user's collections.
  def readable_layer_ids
    # Write permission => read permission in the creation of the permission, but in order to avoid data conflicts
    # we make explicit here that implication
    memberships.includes(:layer_memberships).inject([]){
      | layer_ids, membership |
        (layer_ids | membership.layer_memberships.select{|lm| lm.read == true || lm.write == true}.map(&:layer_id))
    }
  end

  def create_collection(collection)
    return false unless collection.save
    memberships.create! collection_id: collection.id, admin: true
    collection.register_gateways_under_user_owner(self)
    collection
  end

  def admins?(collection)
    memberships.where(:collection_id => collection.id).first.try(:admin?)
  end

  def belongs_to?(collection)
    memberships.where(:collection_id => collection.id).exists?
  end

  def membership_in(collection)
    memberships.where(:collection_id => collection.id).first
  end

  def display_name
    email
  end

  def activities
    Activity.where(collection_id: memberships.pluck(:collection_id))
  end

  def can_view?(collection, option)
    return collection.public if collection.public
    membership = self.memberships.where(:collection_id => collection.id).first
    return false unless membership
    return membership.admin if membership.admin

    return true if(validate_layer_read_permission(collection, option))
    false
  end

  def can_update?(site, properties)
    membership = membership_in(site.collection)
    return false unless membership
    return membership.admin if membership.admin?
    return true if(validate_layer_write_permission(site, properties))
    false
  end

  def validate_layer_write_permission(site, properties)
    membership = membership_in(site.collection)
    properties.each do |prop|
      field = Field.where("code=? && collection_id=?", prop.values[0].to_s, site.collection_id).first
      return false if field.nil?
      lm = LayerMembership.where(membership_id: membership.id, layer_id: field.layer_id).first
      return false if lm.nil?
      return false if(!lm && lm.write)
    end
    return true
  end

  def validate_layer_read_permission(collection, field_code)
    field = Field.where("code=? && collection_id=?", field_code, collection.id).first
    return false if field.nil?
    membership = membership_in(collection)
    lm = LayerMembership.where(membership_id: membership.id, layer_id: field.layer_id).first
    return false if lm.nil?
    return false if(!lm && lm.read)
    return true
  end

  def self.encrypt_users_password
    all.each { |user| user.update_attributes password: user.encrypted_password }
  end

  def get_gateway
    channels.first
  end

  def active_gateway
    channels.where("channels.is_enable=?", true)
  end

  def update_successful_outcome_status
    self.success_outcome = layer_count? & collection_count? & site_count? & gateway_count?
  end

  def collections_i_admin
    self.memberships.includes(:collection).where(:admin => true).map {|m| { id: m.collection.id, name: m.collection.name }}
  end
end
