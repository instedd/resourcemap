class ChannelsController < ApplicationController
  before_action :authenticate_user!

  def index
    respond_to do |format|
      format.html do
        show_collection_breadcrumb
        add_breadcrumb "Properties", collection_path(collection)
        add_breadcrumb "Channels", collection_channels_path(collection)
      end
      format.json { render_json collection.channels.all }
    end
  end

  end
