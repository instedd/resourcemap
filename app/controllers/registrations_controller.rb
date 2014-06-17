class RegistrationsController < Devise::RegistrationsController

  def new
    super
  end

  def create
    super
  end

  def validate_credentials
    if !(params.has_key?(:user) && params.has_key?(:password))
      render_json({ message: _("Invalid parameters. Parameters should include 'user' and 'password'.")}, status: :bad_request)
    else
      user = User.find_for_authentication(:email => params[:user])
      if user && user.valid_password?(params[:password]) && user.active_for_authentication?
        render_json({ message: _('Valid credentials')}, status: :ok)
      else
        render_json({ message: _('Invalid credentials')}, status: :unprocessable_entity)
      end
    end
  end

  def update
    if params[:user][:current_password].blank? && params[:user][:password].empty? && params[:user][:password_confirmation].empty?
      current_user.update_attributes(params.slice(:phone_number))
      redirect_to collections_path, notice: _("Account updated successfully")
    else
      super
    end
  end

end
