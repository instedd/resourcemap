class ImportJob < ActiveRecord::Base
  # The status field captures the lifecycle of an ImportJob. Currently it is:
  #
  # :file_uploaded => :pending
  #                        => :in_progress
  #                            => :finished
  #                            => :failed
  #                        => :canceled_by_user
  #
  # :file_uploaded: a CSV file has been uploaded, but the import process for it hasn't been executed yet.
  # :pending: there's an import job enqueued in Resque waiting to be processed.
  # :in_progress: the import is being processed by the worker.
  # :finished: the import was already processed.
  # :canceled_by_user: the user canceled the import when the job was in status pending. This job will not be processed.

  # :finished_at is nil until the ImportJob reaches the :finished status, when its assigned Time.now

  attr_accessible :finished_at, :original_filename, :status

  belongs_to :user
  belongs_to :collection

  def pending
    Rails.logger.error "Inconsistent status for job with id #{self.id}. Should be in status 'file_uploaded' before marking it as 'pending'" unless self.status_file_uploaded?
    self.status = :pending
    self.save!
  end

  def canceled_by_user
    Rails.logger.error "Inconsistent status for job with id #{self.id}. Should be in status 'pending' before marking it as 'canceled'" unless self.status_pending?
    self.status = :canceled_by_user
    self.save!
  end

  def in_progress
    Rails.logger.error "Inconsistent status for job with id #{self.id}. Should be in status 'pending' before marking it as 'in_progress'" unless self.status_pending?
    self.status = :in_progress
    self.save!
  end

  def self.uploaded(original_filename, user, collection)
    j = ImportJob.new :original_filename => original_filename, :status => :file_uploaded
    j.user = user
    j.collection = collection
    j.save!
  end

  def self.last_for(user, collection)
    user = user.id if user.is_a?(User)
    collection = collection.id if collection.is_a?(Collection)

    ImportJob.where(:collection_id => collection, :user_id => user).last
  end

  def finish
    Rails.logger.error "Inconsistent status for job with id #{self.id}. Should be in status 'in_progress' before marking it as 'finished'" unless self.status_in_progress?
    self.status = :finished
    self.finished_at = Time.now
    self.save!
  end

  def failed(exception)
    Rails.logger.error "Inconsistent status for job with id #{self.id}. Should be in status 'in_progress' before marking it as 'failed'" unless self.status_in_progress?
    self.status = :failed
    self.exception = "#{exception.message}\n#{exception.backtrace.join "\n"}"
    self.finished_at = Time.now
    self.save!
  end

  [:file_uploaded, :pending, :in_progress, :finished, :failed, :canceled_by_user].each do |status_value|
    class_eval %Q(def status_#{status_value.to_s}?; self.status == '#{status_value.to_s}'; end)
  end

end
