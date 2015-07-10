require "yaml"
require "json"
require "../src/crystal-resmap-api-server"

action = ARGV[0]
json_params = JSON.parse(ARGV[1]) as Hash(String, JSON::Type)
rails_root = ARGV[2]
environment = ARGV[3]

database_config = YAML.load(File.read(File.join(rails_root, "config", "database.yml"))) as Hash(YAML::Type, YAML::Type)
database_env_config = database_config[environment] as Hash(YAML::Type, YAML::Type)

Database.new(database_env_config).make_default

Routes.new.route(action, json_params)
