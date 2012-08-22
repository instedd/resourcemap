class Channels::Plugin < Plugin
  
  collection_tab "/channels_tab"

  routes {
    resources :collections do
      resources :channels do
      end
    end
  }
end
