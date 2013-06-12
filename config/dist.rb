set :application, 'resourcemap'
set :version, '2.0.3'
set :maintainer, 'Carolina Hadad <chadad@manas.com.ar>'
set :description, 'InSTEDD Resource Map'
set :summary, description

use :mail

config :settings do
  string :host, prompt: "Host name"
end

config :newrelic do
  string :license_key, prompt: "New Relic license key (leave empty to disable)"
end
