class MembershipsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :authenticate_collection_admin!, :only => [:create, :destroy, :set_layer_access, :set_admin, :unset_admin, :index]

  def collections_i_admin
    render_json current_user.collections_i_admin(params)
  end

  def index
    memberships = collection.memberships.includes([:read_sites_permission, :write_sites_permission, :name_permission, :location_permission]).all.map do |membership|
      membership.to_json
    end
    render_json memberships
  end

  def create
    user = User.find_by_email params[:email]
    if user && !user.memberships.where(:collection_id => collection.id).exists?
      user.memberships.create! :collection_id => collection.id
      render_json({status: :added, user_id: user.id, user_display_name: user.display_name})
    else
      render_json({status: :not_added})
    end
  end

  def invitable
    users = User.
      where('email LIKE ?', "#{params[:term]}%").
      where("id not in (?)", collection.memberships.value_of(:user_id)).
      order('email')
    render_json users.pluck(:email)
  end

  def search
    users = User.
      where('email LIKE ?', "#{params[:term]}%").
      where("id in (?)", collection.memberships.value_of(:user_id)).
      order('email')
    render_json users.pluck(:email)
  end

  def destroy
    membership = collection.memberships.find_by_user_id params[:id]
    if membership.user_id != current_user.id
      membership.destroy
    end
    redirect_to collection_members_path(collection)
  end

  def set_access
    membership = collection.memberships.find_by_user_id params[:id]
    membership.set_access params
    render_json :ok
  end

  #TODO: move set_layer_access to the more generic set_access
  def set_layer_access
    membership = collection.memberships.find_by_user_id params[:id]
    membership.set_layer_access params
    render_json :ok
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

    render_json :ok
  end
end
