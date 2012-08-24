class ChannelsController < ApplicationController
  before_filter :authenticate_user!
  
  def index
    channels = Channel.all
    respond_to do |format| 
      format.html do
        show_collection_breadcrumb
        add_breadcrumb "Channels", collection_channels_path(collection)
      end
      format.json { render json: channels }
    end
  end

end
