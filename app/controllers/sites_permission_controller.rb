class SitesPermissionController < ApplicationController
  before_filter :authenticate_collection_admin!, only: :create

  def index
    membership = current_user.membership_for_collection(collection)
    render json: membership.sites_permission
  end

  def create
    membership = collection.memberships.find_by_user_id params[:sites_permission].delete :user_id
    membership.update_sites_permission params[:sites_permission]

    render json: :ok
  end
end
