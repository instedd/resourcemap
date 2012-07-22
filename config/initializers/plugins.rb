ActionDispatch::Reloader.to_prepare do
  Dir["#{Rails.root}/plugins/*"].each do |plugin_dir|
    plugin_name = File.basename plugin_dir
    plugin_name.camelize.constantize::Plugin.instance

    ActionController::Base.append_view_path "#{plugin_dir}/views"
    Dir["#{plugin_dir}/assets/*"].each do |assets_dir|
      Rails.configuration.assets.paths << assets_dir
      Rails.configuration.assets.precompile << "#{plugin_name}.js"
      Rails.configuration.assets.precompile << "#{plugin_name}.css"
    end

    if Rails.env == "development"
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
end

class ActiveRecord::Migrator
  cattr_accessor :current_plugin

  class << self

    def migrations_paths_with_plugins
      if current_plugin
        ["plugins/#{current_plugin}/db/migrate"]
      else
        migrations_paths_without_plugins
      end
    end
    alias_method_chain :migrations_paths, :plugins

    def get_all_versions_with_plugins
      return get_all_versions_without_plugins unless current_plugin
      table = Arel::Table.new(schema_migrations_table_name)
      ActiveRecord::Base.connection.select_values(table.project(table['version'])).select{ |v| v.match(/-#{current_plugin}/) }.map{ |v| v.to_i }.sort
    end
    alias_method_chain :get_all_versions, :plugins

  end

  def record_version_state_after_migrating_with_plugins(version)
    return record_version_state_after_migrating_without_plugins(version) unless current_plugin
    record_version_state_after_migrating_without_plugins(version.to_s + "-" + current_plugin.to_s)
  end
  alias_method_chain :record_version_state_after_migrating, :plugins
end
