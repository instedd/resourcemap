set :application, 'resourcemap'
set :version, '2.1'
set :maintainer, 'Carolina Hadad <chadad@manas.com.ar>'
set :description, 'InSTEDD Resource Map'
set :summary, description

use :mail

before_build "rake deploy:generate_revision_and_version[#{get :version}]"

after_install "rake index:recreate"

config :settings do
  string :host, prompt: "Host name"
end

config :newrelic do
  string :license_key, prompt: "New Relic license key (leave empty to disable)"
end
