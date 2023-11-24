class Api::MembershipsController < ApiController

  before_action :authenticate_collection_admin!, :only => [:create, :index, :destroy]

  def index
    render_json collection.memberships.includes([:read_sites_permission, :write_sites_permission, :name_permission, :location_permission])
  end

  def create
    status, membership, user = Membership.check_and_create(params[:email], collection.id)
    if status == :added || status == :membership_exists
      render_json({status: :added, user_id: user.id, user_display_name: user.display_name}, status: 200)
    elsif status == :missing_user
      render_error_response_422("Invalid user")
    else
      render_generic_error_response
    end
  end

  def invitable
    users = User.invitable_to_collection(params[:term], collection.memberships.pluck(:user_id))
    render_json users.pluck(:email)
  end

  def destroy
    membership = collection.memberships.find_by_user_id params[:id]
    if membership.user_id != current_user.id && membership.destroy
      head :ok
    else
      render_generic_error_response("Could not delete membership")
    end
  end

  def set_admin
    membership = collection.memberships.find_by_user_id params[:id]
    membership.activity_user = current_user
    if membership.change_admin_flag true
      head :ok
    else
      render_generic_error_response("User could not be set to admin")
    end
  end

  def unset_admin
    membership = collection.memberships.find_by_user_id params[:id]
    if membership.change_admin_flag false
      head :ok
    else
      render_generic_error_response("Could not revoke admin's privileges for user")
    end
  end

  def set_layer_access
    membership = collection.memberships.find_by_user_id params[:id]
    membership.set_layer_access params
    render_json :ok
  end

end
