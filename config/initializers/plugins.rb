ActiveSupport::Reloader.to_prepare do
  Dir["#{Rails.root}/plugins/*"].each do |plugin_dir|
    plugin_name = File.basename plugin_dir
    plugin_name.camelize.constantize::Plugin.instance

    ActionController::Base.append_view_path "#{plugin_dir}/views"
    Dir["#{plugin_dir}/assets/*"].each do |assets_dir|
      Rails.configuration.assets.paths << assets_dir
      Rails.configuration.assets.precompile << "#{plugin_name}.js"
      Rails.configuration.assets.precompile << "#{plugin_name}.css"
    end

    if Rails.env == "development" || Rails.env == "test"
      Rails.configuration.assets.paths << "#{plugin_dir}/spec/javascripts"
    end

    Dir["#{plugin_dir}/controllers/**.rb"].each do |controller_file|
      controller_class_name = File.basename controller_file, '.*'
      controller_class = controller_class_name.camelize.constantize
      next unless controller_class.ancestors.include? ActionController::Base

      controller_class.class_eval %Q(
        def initialize
          prepend_view_path "#{plugin_dir}/views"
          super
        end
      )
    end
  end

  Plugin.hooks(:extend_model).each do |extension|
    extension[:class].send :include, extension[:with]
  end

  Plugin.hooks(:config).each { |block| block.call }
end

module AR_MigrationContextWithCurrentPlugin
  def migrations_paths
    if self.class.current_plugin
      ["plugins/#{current_plugin}/db/migrate"]
    else
      super
    end
  end

  def get_all_versions(connection = ActiveRecord::Base.connection)
    if current_plugin = self.class.current_plugin
      table = Arel::Table.new(schema_migrations_table_name)
      connection.select_values(table.project(table['version'])).select{ |v| v.match(/-#{current_plugin}/) }.map{ |v| v.to_i }.sort
    else
      super
    end
  end

  def record_version_state_after_migrating(version)
    if current_plugin = self.class.current_plugin
      super(version.to_s + "-" + current_plugin.to_s)
    else
      super
    end
  end
end

class ActiveRecord::MigrationContext
  cattr_accessor :current_plugin

  prepend AR_MigrationContextWithCurrentPlugin
end
