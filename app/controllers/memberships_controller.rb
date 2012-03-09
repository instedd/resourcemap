class MembershipsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :authenticate_collection_admin!, :only => [:create, :destroy]

  def create
    user = User.find_by_email params[:email]
    if user && !user.memberships.where(:collection_id => collection.id).exists?
      user.memberships.create! :collection_id => collection.id
      render json: :added
    else
      render json: :not_added
    end
  end

  def invitable
    users = User.
      where('email LIKE ?', "#{params[:term]}%").
      where("id not in (?)", collection.memberships.value_of(:user_id)).
      order('email').
      all
    render json: users.map(&:email)
  end

  def destroy
    membership = collection.memberships.find(params[:id])
    if membership.user_id != current_user.id
      membership.destroy
    end
    redirect_to collection_members_path(collection)
  end
end
