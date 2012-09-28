class SitesPermissionController < ApplicationController

  def index
    render text: 'hello'
  end

  def create
    membership = collection.memberships.find_by_user_id params[:sites_permission].delete :user_id
    membership.update_sites_permission params[:sites_permission]

    render json: :ok
  end
end
