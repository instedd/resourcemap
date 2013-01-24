class FredApi::FredApiController < ApplicationController
  before_filter :authenticate_user!
  include FredApi::JsonHelper

  expose(:site)

  def show_facility
    search = site.collection.new_search current_user_id: current_user.id
    search.id(site.id)
    results = search.api_results('fred_api')

    # ID is unique. We should only get one result here.
    facility = results[0]

    respond_to do |format|
      format.json { render json: fred_facility_format(facility) }
    end
  end

end