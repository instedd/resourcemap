class ChannelsController < ApplicationController
  before_filter :authenticate_user!
  
  def index
    method = Channel.nuntium_info_methods
    respond_to do |format| 
      format.html do
        show_collection_breadcrumb
        add_breadcrumb "Channels", collection_channels_path(collection)
      end
      format.json { render json: collection.channels.select('share_channels.status,channels.id,channels.collection_id,channels.name,channels.password,channels.nuntium_channel_name,is_manual_configuration, channels.is_share').all.as_json(include: [:collections], except: [:plugins], methods: method)}
    end
  end

  def create
    channel = Channel.create params[:channel]
    share_collections = [collection.id]
    share_collections += params[:channel][:share_collections] if params[:channel][:is_share] == 'true'
    channel.collections = Collection.find share_collections
    
    render json: channel
  end
 
  def update
    channel = Channel.find params[:id]
    channel.update_attributes params[:channel]
    share_collections = [collection.id]
    share_collections += params[:channel][:share_collections] if params[:channel][:is_share] == 'true'
    channel.collections = Collection.find share_collections
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
    share_channel = ShareChannel.where(:channel_id => params[:id], :collection_id => params[:collection_id]).first 
    share_channel.status = params[:status]
    share_channel.save! 
    render json: share_channel
  end
end
