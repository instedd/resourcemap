class Reminder < ActiveRecord::Base
  belongs_to :collection
  belongs_to :repeat
  has_and_belongs_to_many :sites
  serialize :schedule, IceCube::Schedule
  before_save :set_schedule_rule
  before_save :set_next_run

  def reminder_date
    schedule.try(:start_time)
  end

  def reminder_date=(date)
    self.schedule ||= IceCube::Schedule.new
    date = case date
           when String then Time.parse(date)
           when Time then date
           else raise "Invalid date time. Should be Time or String"
           end
    schedule.start_time = date
  end

  def set_schedule_rule
    self.schedule = IceCube::Schedule.new(reminder_date)
    self.schedule.add_recurrence_rule(repeat.rule)
  end

  def set_next_run
    self.next_run = schedule.next_occurrence
  end
end
