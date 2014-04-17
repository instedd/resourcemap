class ApiController < ApplicationController

  skip_before_filter :verify_authenticity_token
  before_filter :authenticate_api_user!
  around_filter :rescue_with_check_api_docs

  def rescue_with_check_api_docs
    yield
  rescue => ex
    Rails.logger.info ex.message
    Rails.logger.info ex.backtrace

    render_generic_error_response(ex.message)
  end

  def render_generic_error_response(message = "", error_code = 1)
    render_json({message: "#{message} - Check the API documentation: https://bitbucket.org/instedd/resource_map/wiki/REST_API", error_code: error_code}, status: 400)
  end

  def render_error_response_422(message = "Entity not found")
    render_json({message: message, error_code: 2}, status: 422)
  end

  rescue_from ActiveRecord::RecordNotFound do |x|
    render_error_response_422
  end

end
