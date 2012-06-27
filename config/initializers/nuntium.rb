class Nuntium
  Config = YAML.load_file(File.expand_path('../../../config/nuntium.yml', __FILE__))[Rails.env]

  def self.new_from_config
    Nuntium.new Config['url'], Config['account'], Config['application'], Config['password']
  end

  def self.config
  	Config
  end

end
