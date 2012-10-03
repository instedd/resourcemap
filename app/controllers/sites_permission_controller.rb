class SitesPermissionController < ApplicationController
  before_filter :authenticate_user!
  before_filter :authenticate_collection_admin!, only: :create

  def index
    membership = current_user.memberships.find_by_collection_id params[:collection_id]
    render json: { read: membership.read_sites_permission, write: membership.write_sites_permission }
  end

  def create
    membership = collection.memberships.find_by_user_id params[:sites_permission].delete :user_id
    membership.update_sites_permission params[:sites_permission]

    render json: :ok
  end
end
