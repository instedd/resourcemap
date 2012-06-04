task :environment

namespace :instance do
  desc "Imports an instance of ResourceMap from a mysql dump"
  task :import, [:mysql_dump_filename] => :environment do |task, args|
    unless args[:mysql_dump_filename]
      abort "Error: you must run `bundle exec rake instance:import[<mysql_dump_filename>]`"
    end

    unless File.exists?(args[:mysql_dump_filename])
      abort "Error: the file #{args[:mysql_dump_filename]} doesn't exist"
    end

    db_config = Rails.configuration.database_configuration[Rails.env]
    cmd = "mysql -u#{db_config['username']} "
    cmd << " -p#{db_config['password']} " if db_config['password'].present?
    cmd << db_config['database']
    cmd << " < #{args[:mysql_dump_filename]}"

    `#{cmd}`

    Rake.application.invoke_task 'index:recreate'
  end
end
