class ApiController < ApplicationController

  skip_before_action :set_gettext_locale
  skip_before_action :redirect_to_localized_url

  skip_before_action :verify_authenticity_token
  before_action :authenticate_api_user!
  around_action :rescue_with_check_api_docs

  def rescue_with_check_api_docs
    yield
  rescue => ex
    Rails.logger.info ex.message
    Rails.logger.info ex.backtrace.join("\n")

    if ex.is_a?(CanCan::AccessDenied)
      render_error_response_403(ex.message)
    elsif ex.is_a?(ActiveRecord::RecordNotFound)
      render_error_response_422(ex.message)
    else
      render_generic_error_response(ex.message)
    end
  end

  def render_generic_error_response(message = "", error_code = 1)
    render_json({message: api_error_message(message), error_code: error_code}, status: 400)
  end

  def render_error_response_422(message = "Unprocessable Entity")
    render_json({message: api_error_message(message), error_code: 2, error_object: message}, status: 422)
  end

  def render_error_response_403(message = "Forbidden")
    render_json({message: api_error_message(message), error_code: 3}, status: 403)
  end

  def render_error_response_409(message = "Conflict")
    render_json({message: api_error_message(message), error_code: 4}, status: 409)
  end

  def forbidden_response
    render_error_response_403
  end

  def api_error_message(message)
    check_api_text = 'Check the API documentation: https://github.com/instedd/resourcemap/wiki/REST_API'
    "#{message} - #{check_api_text}"
  end
end
