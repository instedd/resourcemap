require 'resque_scheduler'
require 'resque_scheduler/server'

ActionDispatch::Reloader.to_prepare do
  Resque.schedule = Hash[*Plugin.hooks(:schedule).map {|x| [x[:class].underscore, x.with_indifferent_access]}.flatten]
end

