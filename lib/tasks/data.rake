task :environment

namespace :data do
  desc "Restore data from sql files"
  task :restore, [:directory] => :environment do |task, args|
    unless args[:directory]
      puts "Usage: $> rake data:restore[{sql_file_directory}] RAILS_ENV={env}"
      exit
    end

    Dir["#{args[:directory]}/*.sql"].sort.each do |filename|
      execute_sql filename
    end
    User.encrypt_users_password
    Reminder.reset_reminders_recurrence_rule
  end
end

def execute_sql(filename)
  open(filename, 'r') do |f|
    mysql_client.query f.read if Rails.env.production?
    puts "finish executing #{filename}"
  end
end

def mysql_client
  db_config = Rails.configuration.database_configuration[Rails.env]
  Mysql2::Client.new(host: db_config['host'], username: db_config['username'], flags: Mysql2::Client::MULTI_STATEMENTS)
end
