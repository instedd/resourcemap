class RegistrationsController < Devise::RegistrationsController

  def new
    super
  end

  def create
    super
  end

  def update
    if params[:user][:current_password].blank? && params[:user][:password].empty? && params[:user][:password_confirmation].empty?
      current_user.update_attributes(params.slice(:phone_number))
      redirect_to collections_path, notice: "Account updated successfully"
    else
      super
    end
  end

end
