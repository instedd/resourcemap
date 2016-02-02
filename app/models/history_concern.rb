module HistoryConcern
  extend ActiveSupport::Concern

  class DefaultStrategy
    def self.create(history)
      history.save!
      history
    end
  end

  class BulkStrategy
    def initialize
      @histories = []
    end

    def create(history)
      if history.is_a?(SiteHistory)
        @histories << history
        flush if @histories.length >= 1000
      else
        DefaultStrategy.create(history)
      end
    end

    def flush
      unless @histories.empty?
        SiteHistory.import @histories
        @histories.clear
      end
    end
  end

  def self.strategy
    Thread.current[:site_history_concern] || DefaultStrategy
  end

  def self.strategy=(strategy)
    Thread.current[:site_history_concern] = strategy
  end

  def self.bulk
    self.strategy = BulkStrategy.new
    yield
  ensure
    self.strategy.flush
    self.strategy = nil
  end

  included do
    history_class_name = "#{name}History"
    @history_class = history_class_name.constantize

    after_create :create_history
    after_update :expire_current_history_and_create_new_one
    before_destroy :expire_current_history

    has_many :histories, :class_name => history_class_name

    class << @history_class
      def at_date(date)
        where "#{table_name}.valid_since <= :date && (:date < #{table_name}.valid_to || #{table_name}.valid_to is null)", date: date
      end
    end
  end

  def create_history
    history_class = self.class.history_class || histories
    history = history_class.new
    attributes.each_pair do |att_name, att_value|
      unless ['id', 'created_at', 'updated_at', 'deleted_at'].include? att_name
        history[att_name] = att_value
      end
    end
    history["valid_since"] = updated_at
    history['user_id'] = self.user.id if self.is_a?(Site)
    history[self.history_concern_foreign_key] = id

    HistoryConcern.strategy.create history
  end

  def current_history
    histories.where(valid_to: nil).first
  end

  def expire_current_history_and_create_new_one
    expire_current_history updated_at
    create_history
  end

  def expire_current_history(valid_to = Time.now)
    current_history.try :update_attributes!, valid_to: valid_to
  end

  module ClassMethods
    def history_class
      @history_class
    end
  end
end
