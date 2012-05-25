class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, :phone_number
  validates_uniqueness_of :phone_number
  validates_presence_of :phone_number 
  validates_numericality_of :phone_number
  has_many :memberships
  has_many :collections, through: :memberships

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

  def can_update?(site)
		can_update_site = false
		if siteMember = Membership.find_by_user_id_and_collection_id(self.id, site.id)
			can_update_site = true
		end
    if membership = self.memberships.where(:collection_id => site.collection).first
      return membership.admin? || can_update_site#AccessRights.can_update?(membership.access_rights) || can_update_resource
    end
    false
  end
end
