module Settings
  extend self

  CONFIG = YAML.load_file(File.expand_path('../../../config/settings.yml', __FILE__))['settings']

  def is_on?(plugin)
    CONFIG['plugins'][plugin.to_s] == true
  end

  def method_missing(method_name)
    if matches = method_name.to_s.match(/(\w+)\?$/)
      CONFIG[matches[1]] == true
    else
      super
    end
  end
end
