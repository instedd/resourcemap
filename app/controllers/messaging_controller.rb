require 'treetop_dependencies'
require 'digest'

class MessagingController < ApplicationController
  helper_method :save_message
  protect_from_forgery :except => :index

  USER_NAME, PASSWORD = 'iLab', '1c4989610bce6c4879c01bb65a45ad43'

  # POST /messaging
  def index
    raise HttpVerbNotSupported.new unless request.post?
    message = save_message
    begin
      message.process! params
    rescue => err
      message.reply = err.message
    ensure
    if (message.reply != "Invalid command")
      message[:collection_id] = get_collection_id(params[:body])
    end
    message.save
    render :text => message.reply, :content_type => "text/plain"
    end
  end

  def authenticate
    authenticate_or_request_with_http_basic 'Dynamic Resource Map - HTTP' do |username, password|
      USER_NAME == username && PASSWORD == Digest::MD5.hexdigest(password)
    end
  end

  def get_collection_id(bodyMsg)
    if (bodyMsg[5] == "q")
      collectionId = Message.getCollectionId(bodyMsg, 7)
    elsif (bodyMsg[5] == "u")
      siteCode = Message.getCollectionId(bodyMsg, 7)
      site = Site.find_by_id_with_prefix(siteCode)  
      collectionId = site.collection_id
    end
    return collectionId
  end

  def save_message
    Message.create!(:guid => params[:guid], :from => params[:from], :body => params[:body]) do |m|
      m.country = params[:country]
      m.carrier = params[:carrier]
      m.channel = params[:channel]
      m.application = params[:application]
      m.to = params[:to]
    end
  end
end
