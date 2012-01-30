class ApplicationController < ActionController::Base
  protect_from_forgery

  expose(:collections) { current_user.collections }
  expose(:collection)
  expose(:collection_memberships) { collection.memberships.includes(:user) }
end
