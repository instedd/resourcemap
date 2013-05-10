class ImportJob < ActiveRecord::Base
  # The status field captures the lifecycle of an ImportJob. Currently it is:
  #
  # :file_uploaded => :pending => :finished
  #
  # :file_uploaded: a CSV file has been uploaded, but the import process for it hasn't been executed yet.
  # :pending: there's an import job enqueued in Resque waiting to be processed.
  # :finished: the import was already processed.

  # :finished_at is nil until the ImportJob reaches the :finished status, when its assigned Time.now
  attr_accessible :finished_at, :original_filename, :status

  belongs_to :user
  belongs_to :collection

  def self.uploaded(original_filename, user, collection)
    j = ImportJob.new :original_filename => original_filename, :status => :file_uploaded
    j.user = user
    j.collection = collection
    j
  end

  def self.last_in_status_file_uploaded_for(user, collection)
    last_in_status(:file_uploaded, user, collection)
  end

  def self.last_in_status_pending_for(user, collection)
    last_in_status(:pending, user, collection)
  end

  def finish
    self.status = :finished
    self.finished_at = Time.now
  end

  private

  def self.last_in_status(status, user, collection)
    ImportJob.where(:collection_id => collection.id, :user_id => user.id, :status => status).last
  end
end
