class Channel < ActiveRecord::Base
  has_many :share_channels
  has_many :collections, :through => :share_channels

  serialize :share_collections
  #attr_accessible :channel_name, :collection_id, :is_enable, :is_manual_configuration, :name, :password, :share_collections
  after_create  :register_nuntium_channel
  after_update  :update_nuntium_channel
  after_destroy :delete_nuntium_channel
  
  def generate_nuntium_name
    sprintf("#{Collection.find(collection_id).name.parameterize}-#{self.id}")
  end

  def register_nuntium_channel
    self.nuntium_channel_name = generate_nuntium_name if self.nuntium_channel_name.blank?
    self.password = SecureRandom.base64(6) if self.password.blank?

    config = {
      :name => self.nuntium_channel_name, 
      :kind => 'qst_server',
      :protocol => 'sms',
      :direction => 'bidirectional',
      :enabled => self.is_enable,
      :restrictions => '',
      :priority => 50,
      :configuration => { 
        :password => self.password,
        :friendly_name => self.name,
        :owner_layer_id => self.collection_id
      }
    }

    config.merge!({
      :ticket_code => self.ticket_code, 
      :ticket_message => "This phone will be used for updates and queries on layer #{Collection.find(collection_id).name}.",
    }) unless is_manual_configuration

    handle_nuntium_channel_response Nuntium.new_from_config.create_channel(config)
      
    # Use plain sql query to skip update callback execution
    Channel.update_all({:password => self.password, :nuntium_channel_name => self.nuntium_channel_name}, {:id => self.id})
   
  end
  
  def handle_nuntium_channel_response(response)
    raise get_error_from_nuntium_response(response) if not response['name'] == self.nuntium_channel_name
    response
  end

  def get_error_from_nuntium_response(response)
    return "Error processing nuntium channel" if not response['summary']
    error = response['summary'].to_s
    unless response['properties'].blank?
      error << ': '
      error << response['properties'].map do |dict|
        dict.map{|k,v| "#{k} #{v}"}.join('; ')
      end.join('; ')
    end
    error
  end

  def update_nuntium_channel
    puts '===============' * 10 
    handle_nuntium_channel_response Nuntium.new_from_config.update_channel(
      :name => self.nuntium_channel_name,
      :enabled => self.is_enable,
      :restrictions => '',
      :configuration => { 
        :friendly_name => self.name,
        :owner_layer_id => self.collection_id,
        :password => self.password
      })
  end

  def delete_nuntium_channel
    Nuntium.new_from_config.delete_channel(self.nuntium_channel_name)
    true
  end

  def nuntium_info
    @nuntium_info ||= handle_nuntium_channel_response Nuntium.new_from_config.channel(self.nuntium_channel_name)
  end
  
  def self.nuntium_info_methods
    [:client_last_activity_at, :queued_messages_count, :client_connected, :phone_number]
  end

  def client_last_activity_at
    nuntium_info['last_activity_at'] rescue nil
  end

  def queued_messages_count
    nuntium_info['queued_ao_messages_count'] rescue nil
  end

  def client_connected
    nuntium_info['connected'] rescue nil
  end

end