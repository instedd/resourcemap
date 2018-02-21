class Nuntium
  Config = YAML.load(ERB.new(File.read(File.expand_path('../../../config/nuntium.yml', __FILE__))).result)[Rails.env]

  def self.new_from_config
    Nuntium.new Config['url'], Config['account'], Config['application'], Config['password']
  end

  def self.config
  	Config
  end

end
