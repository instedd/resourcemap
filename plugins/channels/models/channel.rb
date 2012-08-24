class Channel < ActiveRecord::Base
  has_many :share_channels
  has_many :collections, :through => :share_channels

  serialize :share_collections
  #attr_accessible :channel_name, :collection_id, :is_enable, :is_manual_configuration, :name, :password, :share_collections
end
