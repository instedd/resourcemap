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

  def membership_for_collection(collection)
    membership = self.memberships.find_by_collection_id(collection.id)
    if is_guest || !membership
      if (collection.anonymous_name_permission == 'read')
        Membership.new(collection_id: collection.id)
      else
        nil
      end
    else
      membership
    end
  end

  # def membership_for_collection(collection)
  #   if !is_guest
  #     self.memberships.find_by_collection_id(collection.id)
  #   else
  #     if (collection.anonymous_name_permission == 'read')
  #       membership.new(collection_id: collection.id)
  #     else
  #       nil
  #     end
  #   end
  # end

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
    collection.anonymous_name_permission == "read" || memberships.where(:collection_id => collection.id).exists?
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
    return true if (collection.anonymous_name_permission == 'read')
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

  def collections_i_admin(options = {})
    results = self.memberships.includes(:collection).where(:admin => true).select(&:collection).map {|m| { id: m.collection.id, name: m.collection.name }}
    if options[:except_id]
      except_id = options[:except_id].to_i
      results.select! { |result| result[:id] != except_id }
    end
    results
  end

  def ability
    @ability ||= Ability.new(self)
  end
  delegate :can?, :cannot?, :to => :ability

  def self.invitable_to_collection(search_term, user_id)
    User.
      where('email LIKE ?', "#{search_term}%").
      where("id not in (?)", user_id).
      order('email')
  end

  def create_layer_for(collection, params)
    layer = collection.layers.new params
    layer.user = self
    can? :create, layer
    layer.save!
    self.layer_count += 1
    update_successful_outcome_status
    self.save!
  end
end
