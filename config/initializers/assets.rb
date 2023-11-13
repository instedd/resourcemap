# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

Dir[File.expand_path("../../../plugins/*/assets/*", __FILE__)].each do |asset_path|
  next unless File.directory?(asset_path)

  # Add plugin assets directories to the load path:
  Rails.application.config.assets.paths << asset_path

  Dir[File.join(asset_path, "**/*")].each do |asset_file_path|
    next if File.directory?(asset_file_path)
    next if File.extname(asset_file_path) == ".coffee"

    # Add individual asset file to the assets precompilation list:
    Rails.application.config.assets.precompile << asset_file_path.gsub("#{asset_path}/", "")
  end
end

# Precompile plugin javascript assets:
# Rails.application.config.assets.precompile << "alerts.js"
# Rails.application.config.assets.precompile << "channels.js"
# Rails.application.config.assets.precompile << "fred_api.js"
# Rails.application.config.assets.precompile << "reminders.js"
