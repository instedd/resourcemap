class RegistrationsController < Devise::RegistrationsController

  def new
    super
  end

  def create
    super
  end

  def update
    email_changed = current_user.email != params[:user][:email]
    password_changed = !params[:user][:password].empty?
    successfully_updated = if email_changed or password_changed
      current_user.update_with_password(params[:user])
    else
      params[:user].delete(:current_password)
      current_user.update_without_password(params[:user])
    end
    current_user.reset_authentication_token!
    if successfully_updated
      # Sign in the user bypassing validation in case his password changed
      sign_in current_user, :bypass => true
      redirect_to root_path
    else
      render "edit"
    end
  end

end
