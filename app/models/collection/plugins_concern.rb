module Collection::PluginsConcern
  extend ActiveSupport::Concern

  included do
    #serialize :plugins, Hash
  end

  def selected_plugins=(plugin_names)
   # self.plugins = {}
   # plugin_names.each do |name|
   #   next unless name.present?
   #   plugins[name] = {}
   # end
  end

  def plugin_enabled?(key)
    Settings.is_on? key
    #plugins.has_key? key
  end

  def selected_plugins
    Settings.selected_plugins 
    #plugins.keys
  end

  def each_plugin(&block)
    Plugin.find_by_names(*selected_plugins).
      each &block
  end

  # FIXME: not being used
  def call_hooks name, *args
    each_plugin do |plugin|
      plugin.call_hook name, *args
    end
  end

  def method_missing(method_name, *args, &block)
    (method_name =~ /(\w+)_plugin_enabled?/).try(:zero?)? self.plugin_enabled?($1) : super
  end
end
