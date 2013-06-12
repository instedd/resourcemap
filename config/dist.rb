set :application, 'resourcemap'
set :version, '2.0.2'
set :maintainer, 'Carolina Hadad <chadad@manas.com.ar>'
set :description, 'InSTEDD Resource Map'
set :summary, description

use :mail

config :settings do
  string :host, prompt: "Host name"
end
