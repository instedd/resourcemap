set :deploy_user, 'ubuntu'
set :passenger_restart_with_touch, true
set :rvm_ruby_version, "ruby-2.1.8"
server 'staging.instedd.org', user: fetch(:deploy_user), roles: %w{app db web}
