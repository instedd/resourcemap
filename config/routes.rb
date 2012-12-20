ResourceMap::Application.routes.draw do

  devise_for :users, :controllers => {:registrations => "registrations"}

  # match 'messaging' => 'messaging#index'
  match 'nuntium' => 'nuntium#receive', :via => :post
  match 'authenticate' => 'nuntium#authenticate', :via => :post
  match 'android/collections' => 'android#collections_json', :via => :get
  match 'android/submission' => 'android#submission', :via => :post
  match 'collections/breadcrumbs' => 'collections#render_breadcrumbs', :via => :post
  match 'real-time-resource-tracking' => 'home#second_page', :via => :get

  resources :repeats
  resources :collections do
    post :register_gateways
    get :sites_by_term
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
    resources :sites_permission

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

    get 'recreate_index'
    get 'search'
    post 'decode_hierarchy_csv'

    resource :import_wizard, only: [] do
       get 'index'
       post 'upload_csv'
       get 'adjustments'
       get 'guess_columns_spec'
       post 'execute'
       post 'validate_sites_with_columns'
       post 'validate_sites_with_column'
     end

  end

  resources :sites do
    get 'root_sites'
    get 'search', :on => :collection

    post 'update_property'
  end

  resources :activities, :only => [:index], :path => 'activity'
  resources :gateways do
    post 'status', :on => :member
    post 'try' 
  end

  match 'terms_and_conditions' => redirect("http://instedd.org/terms-of-service/")

  namespace :api do
    get 'collections/:id' => 'collections#show',as: :collection
    get 'collections/:id/sample_csv' => 'collections#sample_csv',as: :sample_csv
    get 'collections/:id/count' => 'collections#count',as: :count
    get 'collections/:id/geo' => 'collections#geo_json',as: :geojson
    get 'sites/:id' => 'sites#show', as: :site
    get 'activity' => 'activities#index', as: :activity
    resources :tokens, :only => [:index, :destroy]

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
