class Identity < ActiveRecord::Base
  attr_accessible :provider, :token, :user_id

  belongs_to :user
end
