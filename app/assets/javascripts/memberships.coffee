@initMemberships = (userId, collectionId, admin, layers) ->
  window.userId = userId

  class Expandable extends Module
    constructor: ->
      @expanded = ko.observable false

    toggleExpanded: => @expanded(!@expanded())

    initializeAllReadAllWrite: =>
      @allRead = ko.computed => @allReadOrWrite((x) -> x.canRead())
      @allWrite = ko.computed => @allReadOrWrite((x) -> x.canWrite())

      @allReadUI = ko.computed => @allReadOrWriteUI(=> @allRead())
      @allWriteUI = ko.computed => @allReadOrWriteUI(=> @allWrite())

    allReadOrWrite: (func) =>
      foundFalse = false
      foundTrue = false
      allAdmin = true
      for link in @membershipLayerLinks()
        continue if link.membership.admin()
        allAdmin = false
        foundTrue = true if func(link)
        foundFalse = true unless func(link)
      return 'tristate-checked' if allAdmin
      if foundTrue && foundFalse then "tristate-partial" else if foundTrue then "tristate-checked" else "tristate-unchecked"

    allReadOrWriteUI: (func) =>
      switch func()
        when 'tristate-partial' then '---'
        when 'tristate-checked' then 'Yes'
        when 'tristate-unchecked' then 'No'

    toggleAllRead: =>
      switch @allRead()
        when 'tristate-partial', 'tristate-unchecked'
          link.canRead(true) for link in @membershipLayerLinks()
        else
          link.canRead(false) for link in @membershipLayerLinks()

    toggleAllWrite: =>
      switch @allWrite()
        when 'tristate-partial', 'tristate-unchecked'
          link.canWrite(true) for link in @membershipLayerLinks()
        else
          link.canWrite(false) for link in @membershipLayerLinks()

  class LayerMembership
    constructor: (data) ->
      @layerId = ko.observable data.layer_id
      @read = ko.observable data.read
      @write = ko.observable data.write

  class Layer extends Expandable
    constructor: (data) ->
      super
      @id = ko.observable data?.id
      @name = ko.observable data?.name

    initializeLinks: =>
      @membershipLayerLinks = ko.observableArray $.map(window.model.memberships(), (x) => new MembershipLayerLink(x, @))
      @initializeAllReadAllWrite()

  class MembershipLayerLink
    constructor: (membership, layer) ->
      @membership = membership
      @layer = layer

      @canRead = ko.computed
        read: =>
          if @membership.admin()
            true
          else
            @membership.findLayerMembership(@layer)?.read()
        write: (value) =>
          return if @membership.admin() || value == @canRead()

          $.post "/collections/#{collectionId}/memberships/#{@membership.userId()}/set_layer_access.json", {layer_id: @layer.id(), verb: 'read', access: value}, =>
            lm = @membership.findLayerMembership(@layer)
            if lm
              lm.read value
            else
              @membership.layers().push new LayerMembership(layer_id: @layer.id(), read: value, write: false)
              @membership.layers.valueHasMutated()
        owner: @

      @canWrite = ko.computed
        read: =>
          if @membership.admin()
            true
          else
            @membership.findLayerMembership(@layer)?.write()
        write: (value) =>
          return if @membership.admin() || value == @canWrite()

          $.post "/collections/#{collectionId}/memberships/#{@membership.userId()}/set_layer_access.json", {layer_id: @layer.id(), verb: 'write', access: value}, =>
            lm = @membership.findLayerMembership(@layer)
            if lm
              lm.write value
            else
              @membership.layers().push new LayerMembership(layer_id: @layer.id(), read: false, write: value)
              @membership.layers.valueHasMutated()
        owner: @

      @canReadUI = ko.computed => if @canRead() then "Yes" else "No"
      @canWriteUI = ko.computed => if @canWrite() then "Yes" else "No"

  class Permission
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
      new Permission(@type, all_sites: @allSites(), some_sites: @someSites())

    toJson: ->
      all_sites   : @allSites()
      some_sites  : @someSites()

  class AdvancedMembershipMode
    @constructor: (data)->
      @advancedMode = ko.observable(false)
      @sitesRead = new Permission('read', data.sites?.read)
      @sitesUpdate = new Permission('update', data.sites?.write)
      @error = ko.computed => @sitesRead.error() or @sitesUpdate.error()
      @validAdvancedMembership = ko.computed => !@error()

    @advancedModeOn: ->
      @backupSitesPermission()
      @advancedMode(true)

    @saveSitesPermission: ->
      $.post "/collections/#{collectionId}/sites_permission", sites_permission: user_id: @userId(), read: @sitesRead.toJson(), write: @sitesUpdate.toJson(), =>
        @deleteOriginalSitesPermission()
        @advancedMode(false)

    @cancelAdvancedMembership: ->
      @restoreSitesPermission()
      @advancedMode(false)

    @backupSitesPermission: ->
      @originalSitesRead = @sitesRead.clone()
      @originalSitesUpdate = @sitesUpdate.clone()

    @restoreSitesPermission: ->
      @sitesRead = @originalSitesRead
      @sitesUpdate = @originalSitesUpdate
      @deleteOriginalSitesPermission()

    @deleteOriginalSitesPermission: ->
      delete @originalSitesRead
      delete @originalSitesUpdate

  class Membership extends Expandable
    @include AdvancedMembershipMode

    constructor: (data) ->
      @callModuleConstructors(arguments)
      super
      @userId = ko.observable data?.user_id
      @userDisplayName = ko.observable data?.user_display_name
      @admin = ko.observable data?.admin
      @layers = ko.observableArray $.map(data?.layers ? [], (x) => new LayerMembership(x))

      @adminUI = ko.computed => if @admin() then "<b>Yes</b>" else "No"
      @isCurrentUser = ko.computed => window.userId == @userId()

      @admin.subscribe (newValue) =>
        $.post "/collections/#{collectionId}/memberships/#{@userId()}/#{if newValue then 'set' else 'unset'}_admin.json"

    initializeLinks: =>
      @membershipLayerLinks = ko.observableArray $.map(window.model.layers(), (x) => new MembershipLayerLink(@, x))
      @initializeAllReadAllWrite()

    findLayerMembership: (layer) =>
      lm = @layers().filter((x) -> x.layerId() == layer.id())
      if lm.length > 0 then lm[0] else null

  class @Site
    constructor: (data) ->
      @id = data.id
      @name = data.name

  class MembershipsViewModel
    initialize: (admin, memberships, layers) ->
      @selectedLayer = ko.observable()
      @layers = ko.observableArray $.map(layers, (x) -> new Layer(x))
      @memberships = ko.observableArray $.map(memberships, (x) -> new Membership(x))
      @admin = ko.observable admin

      layer.initializeLinks() for layer in @layers()
      membership.initializeLinks() for membership in @memberships()

      @groupBy = ko.observable("Users")
      @groupByOptions = ["Users", "Layers"]

    destroyMembership: (membership) =>
      if confirm("Are you sure you want to remove #{membership.userDisplayName()} from the collection?")
        $.post "/collections/#{collectionId}/memberships/#{membership.userId()}.json", {_method: 'delete'}, =>
          @memberships.remove membership

  $.get "/collections/#{collectionId}/memberships.json", (memberships) ->
    window.model = new MembershipsViewModel
    window.model.initialize admin, memberships, layers
    ko.applyBindings window.model

    $member_email = $('#member_email')

    createMembership = (email = $member_email.val()) ->
      if $.trim(email).length > 0
        $.post "/collections/#{collectionId}/memberships.json", {email: email}, (data) ->
          if data.status == 'added'
            new_member = new Membership(user_id: data.user_id, user_display_name: data.user_display_name)
            new_member.initializeLinks()
            window.model.memberships.push new_member
            $member_email.val('')

    $member_email.autocomplete
      source: (term, callback) ->
        $.ajax "/collections/#{collectionId}/memberships/invitable.json?#{$.param term}",
          success: (data) ->
            if data.length == 0
              callback(['No users found'])
              $('a', $member_email.autocomplete('widget')).attr('style', 'color: red')
            else
              callback(data)
      select: (event, ui) ->
        if(ui.item.label == 'No users found')
          event.preventDefault()
        else
          createMembership(ui.item.label)
      appendTo: '#autocomplete_container'

    $member_email.keydown (event) ->
      if event.keyCode == 13
        createMembership()

    $('#add_member').click -> createMembership()

    $('.hidden-until-loaded').show()
