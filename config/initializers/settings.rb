module Settings
  extend self

  CONFIG = YAML.load_file(File.expand_path('../../../config/settings.yml', __FILE__))['settings']

  def is_on?(plugin)
    unless status = CONFIG['plugins'][plugin.to_s]
      false
    else
      status
    end
  end
end
