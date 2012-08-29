task :environment

namespace :data do
  desc "Restore data from sql files"
  task :restore, [:directory] => :environment do |task, args|
    unless args[:directory]
      puts "Usage: $> rake data:restore[{sql_file_directory}] RAILS_ENV={env}"
      exit
    end

    Repeat.destroy_all
    Dir.glob("#{args[:directory]}/*.sql").each do |filename|
      execute_sql filename
    end
    User.encrypt_users_password
    Reminder.reset_reminders_recurrence_rule
  end
end

def execute_sql(filename)
  open(filename, 'r') do |f|
    ActiveRecord::Base.connection.execute(f.read) if Rails.env.production?
    puts "finish executing #{filename}"
  end
end
