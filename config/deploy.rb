require 'bundler/capistrano'
require 'rvm/capistrano'

set :rvm_ruby_string, '1.9.3'
set :application, "resource_map"
set :repository,  "ssh://hg@bitbucket.org/instedd/resource_map"
set :scm, :mercurial
set :user, 'ubuntu'
set :deploy_via, :remote_cache
default_environment['TERM'] = ENV['TERM']

namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end

before "deploy:start", "deploy:migrate"
before "deploy:restart", "deploy:migrate"
