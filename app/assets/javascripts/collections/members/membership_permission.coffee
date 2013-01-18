class @MembershipPermission
  constructor: (@type, data) ->
    @allSites = ko.observable(data?.all_sites ? true)
    @someSites = ko.observable(data?.some_sites ? [])
    @access = ko.computed
      read: -> if @allSites() then 'all_sites' else 'some_sites'
      write: (value) ->
        @allSites switch value
          when 'all_sites' then true
          when 'some_sites' then false
          else true
      owner: @
    @error = ko.computed => if @allSites() or @someSites().length > 0 then null else "can #{@type} sites is missing"

  clone: ->
    new MembershipPermission(@type, all_sites: @allSites(), some_sites: @someSites())

  toJson: ->
    all_sites   : @allSites()
    some_sites  : @someSites()
