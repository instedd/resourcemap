# Stage configuration for deploying into the Vagrant box setup by the provided
# Vagrantfile (using rbenv)

# Clear RUBYOPT and RUBYLIB so the Bundle doesn't interfere with the execution
# of vagrant
vagrant_config = `RUBYOPT= RUBYLIB= vagrant ssh-config with-rbenv`
vagrant_config = vagrant_config.split(/\n\s*/).map{ |x| x.split(/\s+/, 2) }
vagrant_config = Hash[vagrant_config]

hostname = vagrant_config['HostName']
username = vagrant_config['User']
identityfile = vagrant_config['IdentityFile'].gsub(/\A"|"\Z/, '')
port = vagrant_config['Port'].to_i

server hostname, user: username, roles: %w{app db web},
       ssh_options: {
         port: port,
         keys: [identityfile],
         auth_methods: %w(publickey)
       }

set :deploy_user, username

set :rbenv_path, '/opt/rbenv'
