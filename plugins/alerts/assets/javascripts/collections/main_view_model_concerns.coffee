onCollections ->
  MainViewModel.include class
    @constructor: ->
      @alertsCount = ko.observable(0)
      @alertsCountText = ko.computed => if @alertsCount() == 1 then '1 alert' else "#{@alertsCount()} alerts"

      @onSitesChanged =>
        alertsCount = 0
        bounds = @map.getBounds()
        for siteId, marker of @markers
          if bounds.contains marker.getPosition()
            alertsCount += 1 if marker.site?.alert == "true"
        for clusterId, cluster of @clusters
          if bounds.contains cluster.position
            alertsCount += cluster.data.alert_count
        alertsCount += 1 if @selectedSite()?.alert?()
        @alertsCount alertsCount
      @aliasMethodChain "setMarkerIcon", "Alerts"

    @setMarkerIconWithAlerts: (marker, icon) ->
      if marker.site && marker.site.alert == 'true' && icon == 'active'
        marker.setIcon @markerImage 'markers/resmap_' + @alertMarker(marker.site.color)  + '_' + marker.site.icon + @endingUrl(icon) + '.png'
        #marker.setIcon @markerImage marker.site.icon
        marker.setShadow null
      else
        @setMarkerIconWithoutAlerts(marker, icon)
