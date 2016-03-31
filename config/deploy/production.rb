set :deploy_user, 'ubuntu'
# set :passenger_restart_with_touch, true
set :rbenv_ruby, "2.1.2"
set :rbenv_path, '/opt/rbenv'

# Deploy stable branch to production by default
set :branch, ENV['BRANCH'] || 'stable'

server 'resourcemap.instedd.org', user: fetch(:deploy_user), roles: %w{app db web}
