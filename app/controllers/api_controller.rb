class ApiController < ApplicationController

  skip_before_filter :verify_authenticity_token
  before_filter :authenticate_api_user!
  around_filter :rescue_with_check_api_docs

  def rescue_with_check_api_docs
    yield
  rescue => ex
    Rails.logger.info ex.message
    Rails.logger.info ex.backtrace

    if ex.is_a?(CanCan::AccessDenied)
      render_error_response_403
    elsif ex.is_a?(ActiveRecord::RecordNotFound)
      render_error_response_422
    else
      render_generic_error_response(ex.message)
    end
  end

  def render_generic_error_response(message = "", error_code = 1)
    render_json({message: api_error_message(message), error_code: error_code}, status: 400)
  end

  def render_error_response_422(message = "Unprocessable Entity")
    render_json({message: api_error_message(message), error_code: 2}, status: 422)
  end

  def render_error_response_403(message = "Forbidden")
    render_json({message: api_error_message(message), error_code: 3}, status: 403)
  end

  def forbidden_response
    render_error_response_403
  end

  def api_error_message(message)
    check_api_text = 'Check the API documentation: https://bitbucket.org/instedd/resource_map/wiki/REST_API'
    "#{message} - #{check_api_text}"
  end
end
