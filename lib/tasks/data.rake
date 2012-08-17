task :environment

namespace :data do
  def encrypt_users_password
    User.all.each do |user|
      user.update_attributes password: user.encrypted_password
    end
  end

  def execute_sql(directory)
    Dir.glob("#{directory}/*.sql").each do |path|
      open(path, 'r') do |f|
        puts "execute #{path}"
        puts ActiveRecord::Base.connection.execute f.read if Rails.env.production?
      end
    end
  end

  def reset_reminder_occurance
    Reminder.all.each do |reminder|
      reminder.save!
    end
  end

  desc "Migrate data from sql files"
  task :migrate, [:directory] => :environment do |task, args|
    unless args[:directory]
      puts "Usage: $> rake data:migrate[{sql_file_directory}] RAILS_ENV={env}"
      exit
    end

    execute_sql args[:directory]
    encrypt_users_password
    reset_reminder_occurance
  end
end
