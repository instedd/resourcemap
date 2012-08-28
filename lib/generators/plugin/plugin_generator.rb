class PluginGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('../templates', __FILE__)

  def setup_directory
    %w(assets controllers models views spec).each do |directory|
      empty_directory "#{plugin_directory}/#{directory}"
    end
  end

  def copy_plugin_file
    template "plugin.rb", "#{plugin_directory}/plugin.rb"
  end

  def copy_controller_file
    template "controller.rb", "#{plugin_directory}/controllers/#{plugin_name}_controller.rb"
  end

  def create_view_file
    create_file "#{plugin_directory}/views/#{plugin_name}/index.haml", "%h2 #{class_name}:index"
  end

  def copy_spec_helper
    copy_file "spec_helper.rb", "#{plugin_directory}/spec/spec_helper.rb"
  end

  private

  def plugin_directory
    @directory ||= "plugins/#{plugin_name}"
  end

  def plugin_name
    name.underscore
  end
end
