class GatewaysController < ApplicationController
  before_action :authenticate_user!, :except => :index

  def index
    method = Channel.nuntium_info_methods
    respond_to do |format|
      format.html
      format.json { render_json(params[:without_nuntium] ?  current_user.channels.where("channels.is_enable=?", true).as_json : current_user.channels.select('channels.id,channels.name,channels.password,channels.nuntium_channel_name,channels.is_enable,channels.basic_setup, channels.advanced_setup, channels.national_setup').as_json(methods: method)) }
    end
  end

  def create
    channel = current_user.channels.create params[:gateway]
    current_user.gateway_count += 1
    current_user.update_successful_outcome_status
    current_user.save!
    render_json channel
  end

  def update
    channel = Channel.find params[:id]
    channel.update_attributes params[:gateway]
    render_json channel
  end

  def destroy
    channel = Channel.find params[:id]
    channel.destroy
    render_json channel
  end

  def try
    channel = Channel.find params[:gateway_id]
    SmsNuntium.notify_sms [params[:phone_number]], 'Welcome to resource map!', channel.national_setup ? channel.nuntium_channel_name[0, channel.nuntium_channel_name.index('-')] : channel.nuntium_channel_name, nil
    render_json channel
  end

  def status
    channel = Channel.find params[:id]
    channel.is_enable = params[:status]
    channel.save!
    render_json channel
  end
end
