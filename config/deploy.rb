require 'bundler/capistrano'

if ENV['RVM']
  require 'rvm/capistrano'
  set :rvm_ruby_string, '2.1.2'
  set :rvm_type, :system
else
  default_run_options[:shell] = "/bin/bash --login"
end

set :application, "resource_map"
set :repository,  "https://github.com/instedd/resourcemap.git"
set :user, 'ubuntu'
set :group, 'ubuntu'
set :deploy_via, :remote_cache
set :branch, ENV['REVISION'] || 'master'

default_run_options[:pty] = true
default_environment['TERM'] = ENV['TERM']

after "deploy", "deploy:cleanup" # keep only the last 5 releases

namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end

  task :symlink_configs, :roles => :app do
    %W(database.yml settings.yml google_maps.key guisso.yml nuntium.yml newrelic.yml poirot.yml telemetry.yml).each do |file|
      run "test -e #{shared_path}/#{file} && ln -nfs #{shared_path}/#{file} #{release_path}/config/ || true"
    end
    run "ln -nfs #{shared_path}/uploads #{release_path}/public/"
  end

  task :generate_revision_and_version do
    run "cd #{current_path} && bundle exec rake deploy:generate_revision_and_version RAILS_ENV=production"
  end
end

namespace :foreman do
  desc 'Export the Procfile to Ubuntu upstart scripts'
  task :export, :roles => :app do
    if ENV['RVM']
      run "echo -e \"PATH=$PATH\\nGEM_HOME=$GEM_HOME\\nGEM_PATH=$GEM_PATH\\nRAILS_ENV=production\" >  #{current_path}/.env"
      run "cd #{current_path} && rvmsudo bundle exec foreman export upstart /etc/init -f #{current_path}/Procfile -a #{application} -u #{user} --concurrency=\"resque=1,resque_scheduler=1\""
    else
      run "echo -e \"PATH=$PATH\\nRAILS_ENV=production\" >  #{current_path}/.env"
      run "cd #{current_path} && #{try_sudo} `which bundle` exec foreman export upstart /etc/init -f #{current_path}/Procfile -a #{application} -u #{user} --concurrency=\"resque=1,resque_scheduler=1\""
    end
  end

  desc "Start the application services"
  task :start, :roles => :app do
    sudo "start #{application}"
  end

  desc "Stop the application services"
  task :stop, :roles => :app do
    sudo "stop #{application}"
  end

  desc "Restart the application services"
  task :restart, :roles => :app do
    run "sudo start #{application} || sudo restart #{application}"
  end
end

before "deploy:start", "deploy:migrate"
before "deploy:restart", "deploy:migrate"

after "deploy:update_code", "deploy:symlink_configs"

after "deploy:update", "foreman:export"    # Export foreman scripts

after "deploy:update", "deploy:generate_revision_and_version"

after "deploy:restart", "foreman:restart"   # Restart application scripts
