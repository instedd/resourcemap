class <%= class_name %>::Plugin < Plugin
  # Sample collection tab
  #   collection_tab "/<%= plugin_name %>_tab"

  # Sample map header view injection
  #   map_header "/<%= plugin_name %>_map_header"

  # Sample site clusterer extension
  #   clusterer \
  #     map: ->(site, hash) do
  #       hash[:alert_count] ||= 0
  #       hash[:alert_count] += (site[:alert] == 'true' ? 1 : 0)
  #     end,
  #     reduce: ->(hash, cluster) { cluster[:alert_count] = hash[:alert_count] }

  # Sample schedule task
  #   schedule \
  #     every: "1m",
  #     class: "<%= class_name %>Task",
  #     queue: "<%= plugin_name %>_queue"

  # Sample model extension
  #   extend_model \
  #     class: Site,
  #     with: Site::<%= class_name %>Concerns

  # Sample field type extension
  #   field_type \
  #     name: "user",
  #     css_class: "luser",
  #     edit_view: "fields/user_edit_view"

  # Sample routes
  #   routes {
  #     resources :collections do
  #       resources :<%= plugin_name %>
  #     end
  #   }
end