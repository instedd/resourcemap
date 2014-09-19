class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_filter :check_guisso_cookie

  def instedd
    load_locale
    generic do |auth|
      {email: auth.info['email']
      }
    end
  end

  def generic
    load_locale
    auth = env['omniauth.auth']

    if identity = Identity.find_by_provider_and_token(auth['provider'], auth['uid'])
      user = identity.user
    else
      attributes = yield auth

      attributes[:confirmed_at] = Time.now

      user = User.find_by_email(attributes[:email])
      unless user
        password = Devise.friendly_token
        user = User.create!(attributes.merge(password: password, password_confirmation: password))
      end
      user.identities.create! provider: auth['provider'], token: auth['uid']
    end

    sign_in user
    next_url = env['omniauth.origin'] || root_path
    next_url = root_path if next_url == new_user_session_url
    redirect_to next_url
  end

  private
  def load_locale
    I18n.locale = session[:omniauth_login_locale] || I18n.default_locale
  end
end
