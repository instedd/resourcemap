Jasmine.configure do |config|
  # guard-jasmine sets the expected port in the environment variable
  config.server_port = (ENV['JASMINE_PORT'] || '8888').to_i
end
