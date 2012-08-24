class ShareChannel < ActiveRecord::Base
  belongs_to :channel
  belongs_to :collection
end
