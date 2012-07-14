class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable

  # Setup accessible (or protected) attributes for your model attr_accessible :email, :password, :password_confirmation, :remember_me, :phone_number
  validates_uniqueness_of :phone_number
  validates_presence_of :phone_number
  has_many :memberships
  has_many :collections, through: :memberships
  has_one :user_snapshot

  def create_collection(collection)
    return false unless collection.save

    memberships.create! collection_id: collection.id, admin: true
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

  def can_write_field?(collection, field_es_code)
    field = collection.fields.where_es_code_is(field_es_code).first
    return false unless field

    membership = membership_in(collection)
    return true if membership.admin?

    lm = LayerMembership.where(user_id: self.id, collection_id: collection.id, layer_id: field.layer_id).first
    lm && lm.write
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
    membership = self.memberships.where(:collection_id => site.collection_id).first
    return false unless membership
    return membership.admin if membership.admin?
    return true if(validate_layer_write_permission(site, properties))
    false
  end

  def validate_layer_write_permission(site, properties)
    properties.each do |prop|
      field = Field.find_by_code(prop.values[0].to_s)
      return false if field.nil?
      lm = LayerMembership.where(user_id: self.id, collection_id: site.collection_id, layer_id: field.layer_id).first
      return false if lm.nil?
      return false if(!lm && lm.write)
    end
    return true
  end

  def validate_layer_read_permission(collection, field_code)
    field = Field.find_by_code field_code
    return false if field.nil?
    lm = LayerMembership.where(user_id: self.id, collection_id: collection.id, layer_id: field.layer_id).first
    return false if lm.nil?
    return false if(!lm && lm.read)
    return true
  end
end
