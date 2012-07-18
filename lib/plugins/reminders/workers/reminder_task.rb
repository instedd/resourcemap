class ReminderTask
  def self.perform    
    Reminder.where("next_run <= ?", Time.now).each do |reminder|
      reminder.save! 
      sites = reminder.sites
      sites.each do |site|
        email = site.properties[site.collection.fields.select { |f| f.kind =='email'}.first.id.to_s]
        phone = site.properties[site.collection.fields.select { |f| f.kind =='phone'}.first.id.to_s]
        reminder_message = sites.reminder_message  
        # send sms and email with reminder_message   
        #
      end
      reminder.save! 
    end
  end
end
