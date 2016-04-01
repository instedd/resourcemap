# config valid only for current version of Capistrano
lock '3.4.0'

set :application, "resource_map"
set :repo_url, "https://github.com/instedd/resourcemap.git"

# Default branch is :master
# ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp
set :branch, ENV['BRANCH'] || 'master'

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, "/u/apps/#{fetch(:application)}"

set :scm, :git
set :format, :pretty
set :log_level, :info
set :pty, true

set :linked_files, fetch(:linked_files, []).concat(%W(
  config/database.yml
  config/google_maps.key
  config/guisso.yml
  config/nuntium.yml
  config/newrelic.yml
  config/poirot.yml
  config/secrets.yml
  config/settings.yml
  config/telemetry.yml
))
set :linked_dirs, fetch(:linked_dirs, []).concat(%W(
  log
  tmp/pids
  tmp/cache
  tmp/sockets
  public/uploads
))

# Default value for keep_releases is 5
set :keep_releases, 5

# Configuration for capistrano/rails
set :rails_env, :production

# System service configuration (ie. worker processes)
set :service_name, fetch(:application)
set :service_opts, { concurrency: 'resque=1,resque_scheduler=1' }

# Configuration for RVM
set :rvm_type, :system
set :rvm_ruby_version, File.read('.ruby-version').strip

# Default configuration for rbenv
set :rbenv_type, :system
set :rbenv_ruby, File.read('.ruby-version').strip
# set :rbenv_path, '/usr/local/rbenv'

# These settings are specific to running rvmsudo correctly
set :rvm_map_bins, fetch(:rvm_map_bins, []).push('rvmsudo')
set :default_env, fetch(:default_env, {}).merge!({'rvmsudo_secure_path' => '1'})

# Tasks related to system services to be managed by upstart or similar
# Uses foreman to export the scripts
namespace :service do
  task :export do
    on roles(:app) do
      opts = {
        app: fetch(:service_name),
        log: File.join(shared_path, 'log'),
        user: fetch(:deploy_user)
      }.merge(fetch(:service_opts))

      execute(:mkdir, "-p", opts[:log])

      export_command = [:bundle, :exec, :foreman, 'export',
                        'upstart', '/etc/init',
                        opts.map { |opt, value| "--#{opt}=\"#{value}\"" }.join(' ')]

      within release_path do
        case fetch(:version_manager)
        when :rvm
          execute :rvmsudo, *export_command
        when :rbenv
          execute :sudo, '-E', fetch(:rbenv_prefix), *export_command
        else
          execute :sudo, *export_command
        end
      end
    end
  end

  # Capture the environment variables for Foreman
  before :export, :set_env do
    on roles(:app) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :bundle, :exec, "env | grep '^\\(PATH\\|GEM_PATH\\|GEM_HOME\\|RAILS_ENV\\)'", "> .env"
        end
      end
    end
  end

  task :safe_restart do
    on roles(:app) do
      execute "sudo stop #{fetch(:service_name)} ; sudo start #{fetch(:service_name)}"
    end
  end
end

namespace :deploy do
  after :updated, "service:export"         # Export foreman scripts
  after :restart, "service:safe_restart"   # Restart background services

  # Write VERSION file in addition to REVISION that Capistrano sets by default
  # VERSION should contain a user-visible version of the application
  after :set_current_revision, :set_current_version do
    on roles(:all) do
      within repo_path do
        set :current_version, capture(:git, :describe, '--always', fetch(:branch))
      end
      within release_path do
        execute :echo, "\"#{fetch(:current_version)}\" > VERSION"
      end
    end
  end

  before :deploy, :info do
    puts "=" * 60
    puts "Deploying branch #{fetch(:branch)} using #{fetch(:version_manager)}"
    roles(:all).each do |host|
      puts "... to #{host.hostname}"
    end
    puts "=" * 60
  end
end
