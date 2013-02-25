class QuotasController < ApplicationController
  before_filter :authenticate_user!
  def index
    @collections = Collection.all
  end

  def create
    collection = Collection.find params["collection_id"]
    collection.quota = collection.quota + params["quota"].to_i
    collection.save!
    redirect_to quotas_path
  end
  
  def show
    collection = Collection.find params["id"]
    render :json => collection
  end
end
