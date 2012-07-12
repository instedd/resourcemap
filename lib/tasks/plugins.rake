task :environment

namespace :plugin do

  def with_plugin(name)
    previous_plugin = ActiveRecord::Migrator.current_plugin
    ActiveRecord::Migrator.current_plugin = name
    begin
      yield
    ensure
      ActiveRecord::Migrator.current_plugin = previous_plugin
    end
  end

  desc "Migrate the database for the specified plugin"
  task :migrate, [:plugin_name] => :environment do |task, args|
    with_plugin args[:plugin_name] do
      Rake::Task['db:migrate'].invoke
    end
  end

  desc "Rolls the schema back to the previous version for the specified plugin"
  task :rollback, [:plugin_name] => :environment do |task, args|
    with_plugin args[:plugin_name] do
      Rake::Task['db:rollback'].invoke
    end
  end
end
