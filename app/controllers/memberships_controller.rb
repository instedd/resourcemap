class MembershipsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :authenticate_collection_admin!, :only => [:create, :destroy, :set_layer_access, :set_admin, :unset_admin]

  def index
    layer_memberships = collection.layer_memberships.all.inject({}) do |hash, membership|
      (hash[membership.user_id] ||= []) << membership
      hash
    end
    memberships = collection.memberships.includes(:user).all.map do |membership|
      {
        user_id: membership.user_id,
        user_display_name: membership.user.display_name,
        admin: membership.admin?,
        layers: (layer_memberships[membership.user_id] || []).map{|x| {layer_id: x.layer_id, read: x.read?, write: x.write?}}
      }
    end
    render json: memberships
  end

  def create
    user = User.find_by_email params[:email]
    if user && !user.memberships.where(:collection_id => collection.id).exists?
      user.memberships.create! :collection_id => collection.id
      render json: {status: :added, user_id: user.id, user_display_name: user.display_name}
    else
      render json: {status: :not_added}
    end
  end

  def invitable
    users = User.
      where('email LIKE ?', "#{params[:term]}%").
      where("id not in (?)", collection.memberships.value_of(:user_id)).
      order('email')
    render json: users.pluck(:email)
  end

  def destroy
    membership = collection.memberships.find_by_user_id params[:id]
    if membership.user_id != current_user.id
      membership.destroy
    end
    redirect_to collection_members_path(collection)
  end

  def set_layer_access
    membership = collection.memberships.find_by_user_id params[:id]
    membership.set_layer_access params
    render json: :ok
  end

  def set_admin
    change_admin_flag true
  end

  def unset_admin
    change_admin_flag false
  end

  private

  def change_admin_flag(new_value)
    membership = collection.memberships.find_by_user_id params[:id]
    membership.admin = new_value
    membership.save!

    render json: :ok
  end
end
