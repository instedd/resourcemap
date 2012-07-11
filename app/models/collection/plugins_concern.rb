module Collection::PluginsConcern
  extend ActiveSupport::Concern

  included do
    serialize :plugins, Hash
  end

  def selected_plugins=(plugin_names)
    self.plugins = {}
    plugin_names.each do |plugin_name|
      next unless plugin_name.present?
      plugins[plugin_name] = {}
    end
    # plugins.delete_if { |name, _| not plugin_names.include? name }
  end

  def selected_plugins
    plugins.keys
  end

  def each_plugin
    Plugin.all.each do |plugin|
      if plugins.keys.include? plugin.name
        yield plugin
      end
    end
  end
end