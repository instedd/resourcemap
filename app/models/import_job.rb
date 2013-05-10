class ImportJob < ActiveRecord::Base
  attr_accessible :finished_at, :original_filename, :status

  belongs_to :user
  belongs_to :collection
end
