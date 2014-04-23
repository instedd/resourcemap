class Api::MembershipsController < ApiController

  before_filter :authenticate_collection_admin!, :only => [:create, :index]

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
    users = User.invitable_to_collection(params[:term], collection.memberships.value_of(:user_id))
    render_json users.pluck(:email)
  end

end
