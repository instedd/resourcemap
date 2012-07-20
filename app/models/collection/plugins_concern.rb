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
  end

  def plugin_enabled?(key)
    plugins.has_key? key
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

  def call_hooks name, *args
    each_plugin do |plugin|
      plugin.call_hook name, *args
    end
  end
end