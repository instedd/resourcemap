# Load DSL and set up stages
require 'capistrano/setup'

# Include default deployment tasks
require 'capistrano/deploy'

task :use_rvm do
  require 'capistrano/rvm'
  set :version_manager, :rvm
end

task :use_rbenv do
  require 'capistrano/rbenv'
  set :version_manager, :rbenv
end

# Set the Ruby version manager from the stage
task 'vagrant-rvm' => [:use_rvm]
task 'vagrant-rbenv' => [:use_rbenv]
task 'staging' => [:use_rvm]
task 'production' => [:use_rbenv]

# Include tasks from other gems included in your Gemfile
require 'capistrano/bundler'
require 'capistrano/rails/assets'
require 'capistrano/rails/migrations'
require 'capistrano/passenger'

# Load custom tasks from `lib/capistrano/tasks` if you have any defined
Dir.glob('lib/capistrano/tasks/*.rake').each { |r| import r }

