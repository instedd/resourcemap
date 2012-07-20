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
            alertsCount += 1 if marker.alert == "true"
        for clusterId, cluster of @clusters
          if bounds.contains cluster.position
            alertsCount += cluster.alertCount
        alertsCount += 1 if @selectedSite()?.alert()
        @alertsCount alertsCount