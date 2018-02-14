GoogleMapsKey = (Settings.google_maps_key || File.read("#{Rails.root}/config/google_maps.key")) rescue ""
