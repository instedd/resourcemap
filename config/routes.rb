ResourceMap::Application.routes.draw do
  mount InsteddTelemetry::Engine => '/instedd_telemetry'
  # We need to define devise_for just omniauth_callbacks:uth_callbacks otherwise it does not work with scoped locales
  # see https://github.com/plataformatec/devise/issues/2813
  devise_for :users, skip: [:session, :password, :registration, :confirmation], controllers: { omniauth_callbacks: 'omniauth_callbacks' }

  scope "(:locale)", :locale => /#{Locales.available.keys.join('|')}/ do
    # We define here a route inside the locale thats just saves the current locale in the session
    get 'omniauth/:provider' => 'omniauth#localized', as: :localized_omniauth

    devise_for :users, skip: :omniauth_callbacks, controllers: {registrations: "registrations"}
    guisso_for :user

    devise_scope :user do
      get "users/validate_credentials" => "registrations#validate_credentials"
    end


    # match 'messaging' => 'messaging#index'
    match 'nuntium' => 'nuntium#receive', :via => :post
    match 'authenticate' => 'nuntium#authenticate', :via => :post
    match 'android/collections' => 'android#collections_json', :via => :get
    match 'android/submission' => 'android#submission', :via => :post
    match 'collections/breadcrumbs' => 'collections#render_breadcrumbs', :via => :post
    match 'real-time-resource-tracking' => 'home#second_page', :via => :get
    match 'track-medical-supplies-and-personnel'=> 'home#medical_page', :via => :get
    match 'track-food-prices-and-supplies' => 'home#food_page', :via => :get
    #match 'analytics' => 'analytics#index', :via => :get

    match 'memberships/collections_i_admin' => 'memberships#collections_i_admin', :via => :get

    match 'collections/:id/import_layers_from/:other_id' => 'collections#import_layers_from', :via => :get

    resources :repeats

    resources :collections do
      post :register_gateways
      get  :message_quota
      get :sites_by_term

      get :current_user_membership

      resources :sites do
        member do
          post 'partial_update'
        end
      end
      resources :layers do
        member do
          put :set_order
        end
        collection do
          post :decode_hierarchy_csv
        end
      end

      resources :fields do
        collection do
          get 'mapping'
        end
        member do
          get 'hierarchy'
        end
      end

      resources :memberships do
        collection do
          get 'invitable'
          get 'search'
          post 'set_layer_access_anonymous_user'
          post 'set_access_anonymous_user'
          delete :leave_collection
        end
        member do
          post 'set_access'
          #TODO: move set_layer_access to the more generic set_access
          post 'set_layer_access'
          post 'set_admin'
          post 'unset_admin'
        end
      end
      resources :sites_permission

      get 'members'
      get 'settings'
      get 'quotas'
      get 'csv_template'
      get 'max_value_of_property'

      post 'create_snapshot'
      post 'load_snapshot'
      post 'unload_current_snapshot'

      get 'recreate_index'
      get 'search'

      get 'sites_info'
      post 'upload_logo'
      get 'edit_logo'
      post 'update_logo'

      resource :import_wizard, only: [] do
         get 'index'
         post 'upload_csv'
         get 'adjustments'
         get 'guess_columns_spec'
         post 'execute'
         post 'validate_sites_with_columns'
         get 'get_visible_sites/:page' => 'import_wizards#get_visible_sites'
         get 'import_in_progress'
         get 'import_finished'
         get 'import_failed'
         get 'job_status'
         get 'cancel_pending_jobs'
         get 'logs'
       end
    end

    resources :sites do
      get 'root_sites'
      get 'search', :on => :collection

      post 'update_property'
    end

    resources :activities, :only => [:index], :path => 'activity'
    resources :quotas
    resources :gateways do
      post 'status', :on => :member
      post 'try'
    end

    match 'terms_and_conditions' => redirect("http://instedd.org/terms-of-service/"), :via => [:get, :post]

    scope '/plugin' do
      Plugin.all.each do |plugin|
        unless plugin.name == 'fred_api'
          scope plugin.name do
            plugin.hooks[:routes].each { |plugin_routes_block| instance_eval &plugin_routes_block }
          end
        end
      end
    end

    match '/locale/update' => 'locale#update',  :as => 'update_locale', :via => [:get, :post]
    root :to => 'home#index'
  end

  scope '/plugin' do
    Plugin.find_by_names('fred_api').each do |plugin|
      scope plugin.name do
        plugin.hooks[:routes].each { |plugin_routes_block| instance_eval &plugin_routes_block }
      end
    end
  end

  namespace :api do
    resources :collections, except: [:update] do
      resources :memberships, only: [:index, :create, :destroy] do
        member do
          post :set_admin
          post :unset_admin
        end
        collection do
          get 'invitable'
        end
      end

      resources :layers, except: [:show, :new, :edit] do
        resources :fields, only: [:create]
      end

      resources :fields, only: [:index] do
        collection do
          get 'mapping'
        end
      end

      member do
        get 'sample_csv', as: :sample_csv
        get 'count', as: :count
        get 'geo', as: :geojson, to: "collections#geo_json"
        post 'sites', to: 'sites#create'
        post 'update_sites', to: 'collections#bulk_update'
      end
    end

    resources :sites, only: [:show, :destroy, :update] do
      member do
        post :update_property
        post :partial_update
      end
    end
    get 'histogram/:field_id', to: 'collections#histogram_by_field', as: :histogram_by_field
    get 'collections/:collection_id/sites/:id/histories' => 'sites#histories', as: :histories
    get 'activity' => 'activities#index', as: :activity
    resources :tokens, :only => [:index, :destroy]
  end

  admin_constraint = lambda do |request|
    request.env['warden'].authenticate? and request.env['warden'].user.is_super_user?
  end

  constraints admin_constraint do
    mount Resque::Server, :at => "/admin/resque"
    match 'analytics' => 'analytics#index', :via => :get
    match 'quota' => 'quota#index', via: :get
  end

  # TODO: deprecate later
  match 'collections/:collection_id/fred_api/v1/facilities/:id' => 'fred_api#show_facility', :via => :get
  match 'collections/:collection_id/fred_api/v1/facilities' => 'fred_api#facilities', :via => :get
  match 'collections/:collection_id/fred_api/v1/facilities/:id' => 'fred_api#delete_facility', :via => :delete
  match 'collections/:collection_id/fred_api/v1/facilities' => 'fred_api#create_facility', :via => :post
  match 'collections/:collection_id/fred_api/v1/facilities/:id(.:format)' => 'fred_api#update_facility', :via => :put
end
