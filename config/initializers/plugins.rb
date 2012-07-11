ActionDispatch::Reloader.to_prepare do
  Dir["#{Rails.root}/lib/plugins/*"].each do |plugin_dir|
    plugin_name = File.basename plugin_dir
    plugin_name.camelize.constantize::Plugin.instance

    ActionController::Base.append_view_path "#{plugin_dir}/views"
    Dir["#{plugin_dir}/assets/*"].each do |assets_dir|
      Rails.configuration.assets.paths << assets_dir
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
end
