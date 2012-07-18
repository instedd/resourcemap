class ReminderTask
  def self.perform    
    Reminder.where("next_run <= ?", Time.now).each do |reminder|
      puts reminder.reminder_message  
      reminder.save! 
      # adding reminder into que
    end
  end
end
