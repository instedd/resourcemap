class Channel < ActiveRecord::Base
  attr_accessible :channel_name, :collection_id, :is_enable, :is_manual_configuration, :name, :password, :share_collections
end
