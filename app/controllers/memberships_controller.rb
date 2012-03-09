class MembershipsController < ApplicationController
  before_filter :authenticate_user!

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
end
