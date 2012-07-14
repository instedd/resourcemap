class SiteReminder < ActiveRecord::Base
  belongs_to :reminder
  belongs_to :site
end
