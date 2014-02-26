load 'deploy' if respond_to?(:namespace) # cap2 differentiator
load 'config/deploy'
load 'deploy/assets'

Dir['vendor/gems/*/recipes/*.rb','vendor/plugins/*/recipes/*.rb'].each { |plugin| load(plugin) }
