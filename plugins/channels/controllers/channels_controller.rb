class ChannelsController < ApplicationController
  before_filter :authenticate_user!
  
  def index
    method = Channel.nuntium_info_methods
    respond_to do |format| 
      format.html do
        show_collection_breadcrumb
        add_breadcrumb "Channels", collection_channels_path(collection)
      end
      format.json { render json: collection.channels.all.as_json(include: [:share_channels, :collections], except: [:plugins], methods: method)}
    end
  end

  def create
    channel = Channel.create params[:channel]
    channel.collections = Collection.find params[:channel][:share_collections] + [collection.id] unless params[:channel][:is_share]
    render json: channel
  end
 
  def update
    channel = Channel.find params[:id]
    channel.update_attributes params[:channel]
    channel.collections = Collection.find params[:channel][:share_collections] unless params[:channel][:is_share]
    render json: channel
  end
  
  def get_shared_channels
    shared_channels = collection.channels 
    format.json { render json: shared_channels }
  end

 # def show
 #   channel = collection.channels.find(params[:id]) 
 #   puts '--------------' * 9 
 #   puts channel.to_json 
 #   method = if params[:nuntium_info] then Channel.nuntium_info_methods else [] end
 #   render :json => channel.to_json(:methods => method)
 # end
end
