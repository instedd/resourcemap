class GatewaysController < ApplicationController
  before_filter :authenticate_user!
  def index
    method = Channel.nuntium_info_methods
    respond_to do |format|
      format.html 
      format.json { render json: params[:without_nuntium] ?  current_user.channels.where("channels.is_enable=?", true).all.as_json : current_user.channels.select('channels.id,channels.collection_id,channels.name,channels.password,channels.nuntium_channel_name,channels.is_enable,channels.basic_setup, channels.advanced_setup, channels.national_setup, channels.is_manual_configuration, channels.is_share').all.as_json(methods: method)}    
    end
  end

  def create
    channel = current_user.channels.create params[:gateway]
    render json: channel.as_json
  end

  def update
    channel = Channel.find params[:id]
    channel.update_attributes params[:gateway]
    render json: channel
  end

  def destroy
    channel = Channel.find params[:id]
    channel.destroy
    render json: channel 
  end

  def try
    channel = Channel.find params[:gateway_id]
    puts channel.to_json 
    SmsNuntium.notify_sms [params[:phone_number]], 'Welcome to resource map!', channel.national_setup ? channel.nuntium_channel_name[0, channel.nuntium_channel_name.index('-')] : channel.nuntium_channel_name
    render json: channel.as_json
  end
  
  def status
    channel = Channel.find params[:id] 
    channel.is_enable = params[:status]
    channel.save!
    render json: channel
  end
end
