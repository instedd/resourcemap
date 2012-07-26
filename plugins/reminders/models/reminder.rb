class Reminder < ActiveRecord::Base
  belongs_to :collection
  belongs_to :repeat
  serialize :schedule, IceCube::Schedule
  serialize :sites, Array 
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

  def target_sites
    if is_all_site
      collection.sites 
    else
      sites
    end
  end
end
