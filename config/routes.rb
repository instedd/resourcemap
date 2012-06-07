ResourceMap::Application.routes.draw do
  devise_for :users
  match 'messaging' => 'messaging#index'
  resources :repeats
  resources :collections do
    resources :sites
    resources :layers do
      member do
        put :set_order
      end
    end
    resources :fields
    resources :thresholds do
      member do
        post :set_order
      end
    end
    resources :reminders

    resources :memberships do
      collection do
        get 'invitable'
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
    post 'create_snapshot'

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

  root :to => 'home#index'
end
