ResourceMap::Application.routes.draw do
  devise_for :users
  # match 'messaging' => 'messaging#index'
  match 'nuntium' => 'nuntium#receive', :via => :post
  match 'authenticate' => 'nuntium#authenticate', :via => :post
  match 'android/collections' => 'android#collections_json', :via => :get


  resources :repeats
  resources :collections do
    resources :sites
    resources :layers do
      member do
        put :set_order
      end
    end
    resources :fields

    resources :memberships do
      collection do
        get 'invitable'
        get 'search'
      end
      member do
        post 'set_layer_access'
        post 'set_admin'
        post 'unset_admin'
      end
    end
    get 'members'
    get 'settings'
    get 'csv_template'
    get 'max_value_of_property'

    post 'upload_csv'

    member do
      post 'create_snapshot'
      post 'load_snapshot'
      post 'unload_current_snapshot'
    end

    get 'import_wizard'
    post 'import_wizard_upload_csv'
    get 'import_wizard_adjustments'
    get 'import_wizard_sample'
    post 'import_wizard_execute'

    get 'recreate_index'
    get 'search'
    post 'decode_hierarchy_csv'
  end

  resources :sites do
    get 'root_sites'
    get 'search', :on => :collection

    post 'update_property'
  end

  resources :activities, :only => [:index], :path => 'activity'
  resources :gateways

  get 'terms_and_conditions', :to => redirect('/')

  namespace :api do
    get 'collections/:id' => 'collections#show',as: :collection
    get 'collections/:id/count' => 'collections#count',as: :count
    get 'collections/:id/geo' => 'collections#geo_json',as: :geojson
    get 'sites/:id' => 'sites#show', as: :site
    get 'activity' => 'activities#index', as: :activity
  end

  scope '/plugin' do
    Plugin.all.each do |plugin|
      scope plugin.name do
        plugin.hooks[:routes].each { |plugin_routes_block| instance_eval &plugin_routes_block }
      end
    end
  end

  root :to => 'home#index'
  resque_constraint = lambda do |request|
    request.env['warden'].authenticate? and request.env['warden'].user.is_super_user?
  end

  constraints resque_constraint do
    mount Resque::Server, :at => "/admin/resque"
  end
end
