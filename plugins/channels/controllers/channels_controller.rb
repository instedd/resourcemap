class ChannelsController < ApplicationController
  before_filter :authenticate_user!
  
  def index
    method = Channel.nuntium_info_methods
    respond_to do |format| 
      format.html do
        show_collection_breadcrumb
        add_breadcrumb "Channels", collection_channels_path(collection)
      end
      format.json { render json: collection.channels.all.as_json(include: [:share_channels, :collections], except: [:plugins])}
    end
  end

  def create
    channel = Channel.create params[:channel]
    channel.collections = Collection.find params[:channel][:share_collections] + [collection.id] if params[:channel][:is_share]
    render json: channel
  end
 
  def update
    channel = Channel.find params[:id]
    channel.update_attributes params[:channel]
    channel.collections = Collection.find params[:channel][:share_collections] if params[:channel][:is_share]
    render json: channel
  end
  
  def get_shared_channels
    shared_channels = collection.channels 
    format.json { render json: shared_channels }
  end

  def destroy
    channel = Channel.find params[:id]
    channel.destroy
    render json: channel 
  end

  def set_status
    channel = Channel.find params[:id]
    channel.status = params[:status]
    channel.save! 
    render json: channel
  end
end
