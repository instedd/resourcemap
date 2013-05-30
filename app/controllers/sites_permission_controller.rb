class SitesPermissionController < ApplicationController
  before_filter :authenticate_user!
  before_filter :authenticate_collection_admin!, only: :create

  before_filter :setup_guest_user, :if => Proc.new { collection && collection.public }
  before_filter :authenticate_user!, :unless => Proc.new { collection && collection.public }

  def index
    membership = current_user.memberships.find_by_collection_id params[:collection_id]
    render json: membership.sites_permission
  end

  def create
    membership = collection.memberships.find_by_user_id params[:sites_permission].delete :user_id
    membership.update_sites_permission params[:sites_permission]

    render json: :ok
  end
end
