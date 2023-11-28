ActiveSupport::Reloader.to_prepare do
  Resque.schedule = Hash[*Plugin.hooks(:schedule).map {|x| [x[:class].underscore, x.with_indifferent_access]}.flatten]
end

