class Channels::Plugin < Plugin
  
  collection_tab "/channels_tab"

  routes {
    resources :collections do
      resources :channels do
        get :get_shared_channels, :on => :member
      end
    end
  }
end
