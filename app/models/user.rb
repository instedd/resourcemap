class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me

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

  def can_write_field?(collection, field_code)
    field = collection.fields.where(:code => field_code).first
    return false unless field

    membership = membership_in(collection)
    return true if membership.admin?

    lm = LayerMembership.where(user_id: self.id, collection_id: collection.id, layer_id: field.layer_id).first
    lm && lm.write
  end

  def activities
    Activity.where(collection_id: memberships.pluck(:collection_id))
  end
end
