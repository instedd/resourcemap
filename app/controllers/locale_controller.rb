class LocaleController < ApplicationController

  def update
    url = Rails.application.routes.recognize_path(request.referer)
    locale = url[:locale] = session[:locale] = params[:requested_locale]
    # current_user.update_attribute :lang, locale.to_s if current_user
    redirect_to url
  end

end
