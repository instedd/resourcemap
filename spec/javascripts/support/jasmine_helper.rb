Jasmine.configure do |config|
  # guard-jasmine sets the expected port in the environment variable
  config.server_port = (ENV['JASMINE_PORT'] || '8888').to_i

  # don't auto-install phantomjs; use the one in the PATH
  config.prevent_phantom_js_auto_install = true
end
