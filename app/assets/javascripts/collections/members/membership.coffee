#= require collections/members/expandable

class @Membership extends Expandable
  constructor: (root, data) ->
    super
    _self = @
    @root = root

    $(window).scroll ->
      isSticky = $(".table-header").hasClass("sticky")
      table_header = $(".table-header")
      table = $("#memberPermissionsTable")
      return unless table.length > 0

      should_be_sticky = $(this).scrollTop() > table.offset().top && ($(this).scrollTop() < table.offset().top + table.outerHeight())
      if should_be_sticky
        table_header.css('top', Math.min(0, table.offset().top + table.outerHeight() - table_header.outerHeight() - $('#add_member_container').outerHeight() - $(this).scrollTop()) )
        if !isSticky
          table_header.addClass "sticky"
          $(".membersFirstRow td").css("padding-top", $(".table-header").height())
      else
        if isSticky
          table_header.removeClass "sticky"
          $(".membersFirstRow td").css("padding-top", '')

    # Defined this before callModuleConstructors because it's used by MembershipLayout
    @userId = ko.observable data?.user_id
    @userDisplayName = ko.observable data?.user_display_name
    @admin = ko.observable data?.admin
    @collectionId = ko.observable root.collectionId()
    @namePermission = ko.observable data?.name
    @locationPermission = ko.observable data?.location
    @isAnonymous = false

    @showAdminCheckbox = true
    @defaultRead = ko.observable(false)
    @defaultWrite = ko.observable(false)

    rootLayers = data?.layers ? []
    @layers = ko.observableArray $.map(root.layers(), (x) => new LayerMembership(x, rootLayers, _self))

    @sitesWithCustomPermissions = ko.observableArray SiteCustomPermission.arrayFromJson(data?.sites, @)

    @callModuleConstructors(arguments)

    @set_layer_access_path = ko.computed => "/collections/#{@collectionId()}/memberships/#{@userId()}/set_layer_access.json"

    @set_access_path = ko.computed => "/collections/#{@collectionId()}/memberships/#{@userId()}/set_access.json"

    @allNoneNameLocationPerm = ko.observable('read')

    @writeNamePermission = (action) =>
      @namePermission(action)
      $.post @set_access_path(), { object: 'name', new_action: action}

    @writeLocationPermission = (action) =>
      @locationPermission(action)
      $.post @set_access_path(), { object: 'location', new_action: action}

    for action in ['none', 'read', 'update']
      do (action) =>
        this["#{action}NameChecked"] = ko.computed
          read: =>
            if @namePermission() == action
              "true"
            else
              ""
          write: (val) =>
            @writeNamePermission action

        this["#{action}LocationChecked"] = ko.computed
          read: =>
            if @locationPermission() == action
              "true"
            else
              ""
          write: (val) =>
            @writeLocationPermission action

    all = (permitted) ->
      _.all _self.layers(), (l) => permitted l

    some = (permitted) ->
      (_.some _self.layers(), (l) => permitted l) and not all permitted

    none = (permitted) ->
      not _.any _self.layers(), (l) => permitted l

    summarize = (permitted) ->
      return __('All') if all permitted
      return __('Some') if some permitted
      return '' if none permitted

    nonePermission = (l) => not @admin() and not l.read() and not l.write()
    readPermission = (l) => not @admin() and l.read() and not l.write()
    writePermission = (l) => @admin() or l.write()

    @adminUI = ko.computed => if @admin() then "<b>#{__("Yes")}</b>" else __("No")
    @isCurrentUser = ko.computed => window.userId == @userId()

    @admin.subscribe (newValue) =>
      $.post "/collections/#{root.collectionId()}/memberships/#{@userId()}/#{if newValue then 'set' else 'unset'}_admin.json"

    @someLayersNone = ko.computed => some nonePermission

    @allLayersNone = ko.computed
      read: =>
        return 'all' if ((all nonePermission) && @namePermission() == @allNoneNameLocationPerm() && @locationPermission() == @allNoneNameLocationPerm() )
        ''
      write: (val) =>
        return unless val

        if !@isAnonymous
          @readNameChecked(true)
          @readLocationChecked(true)
        else
          @noneNameChecked(true)
          @noneLocationChecked(true)

        _self = @

        _.each @layers(), (layer) ->
          layer.read false
          layer.write false
          $.post _self.set_layer_access_path(), { layer_id: layer.layerId(), verb: 'read', access: false}

    @allLayersRead = ko.computed
      read: =>
        return 'all' if ((all readPermission) && @namePermission() == 'read' && @locationPermission() == 'read')
        ''
      write: (val) =>
        return unless val

        @readNameChecked(true)
        @readLocationChecked(true)

        _self = @
        _.each @layers(), (layer) ->
          layer.read true
          layer.write false
          $.post _self.set_layer_access_path(), { layer_id: layer.layerId(), verb: 'read', access: true}


    @allLayersUpdate = ko.computed
      read: =>
        return 'all' if ((all writePermission) && @namePermission() == 'update' && @locationPermission() == 'update')
        ''
      write: (val) =>
        return unless val

        @updateNameChecked(true)
        @updateLocationChecked(true)

        _self = @
        _.each @layers(), (layer) ->
          layer.write true
          layer.read true
          $.post _self.set_layer_access_path(), { layer_id: layer.layerId(), verb: 'write', access: true}

    @isNotAdmin = ko.computed => not @admin()

    @summaryNone = ko.computed => summarize nonePermission
    @summaryRead = ko.computed => summarize readPermission
    @summaryUpdate = ko.computed => summarize writePermission
    @summaryAdmin = ko.computed => ''

    @site_permissions_title = ko.computed =>
      if @sitesWithCustomPermissions().length == 0
        __("Custom permissions for sites")
      else if @sitesWithCustomPermissions().length == 1
        __("Custom permissions for 1 site")
      else
        Jed.sprintf(_("Custom permissions for %d sites"), @sitesWithCustomPermissions().length)


    @customPermissionsAutocompleteId = ko.computed => "autocomplete_#{@userId()}"

    #Setup autocomplete to add custom permissions per site
    $custom_permissions_autocomplete = $("##{@customPermissionsAutocompleteId()} #custom_site_permission")

    @searchSitesUrl = ko.observable "/collections/#{@collectionId()}/sites_by_term.json"

    @customSite = ko.observable ''

    @confirming = ko.observable false

    @createCustomPermissionForSite = () =>
      if $.trim(@customSite()).length > 0
        # TODO: filter results so that they don't include already added sites.
        # Until we do that, we'll just ignore attempts to create duplicates... :(
        return if SiteCustomPermission.findBySiteName(@sitesWithCustomPermissions(), @customSite())?

        $.get "#{@searchSitesUrl()}?term=#{@customSite()}", { term: @customSite() }, (data) ->
          # Check that a site with that name exists
          _.each data, (s) ->
            if s.name == _self.customSite()
              new_permission = new SiteCustomPermission s.id, s.name, true, true, _self
              _self.sitesWithCustomPermissions.push new_permission
              _self.customSite ""
              _self.saveCustomSitePermissions()


    @removeCustomPermission = (site_permission) =>
      @sitesWithCustomPermissions.remove site_permission
      @saveCustomSitePermissions()

    @defaultLayerPermissionsExpanded = ko.observable true

    @defaultLayerPermissionsArrow = (base_uri) =>
      if @defaultLayerPermissionsExpanded()
        "#{base_uri}/theme/images/icons/misc/black/arrowDown.png"
      else
        "#{base_uri}/theme/images/icons/misc/black/arrowRight.png"

  nameLocationDisabled: () =>
    if @isAnonymous
      @summaryRead() != ''
    else
      true

  updateCheckboxVisible: () =>
    return !@isAnonymous

  toggleDefaultLayerPermissions: =>
    @defaultLayerPermissionsExpanded(not @defaultLayerPermissionsExpanded())

  open_confirm: =>
    @confirming true

  close_confirm: =>
    @confirming false

  confirm: =>
    $.post "/collections/#{@collectionId()}/memberships/#{@userId()}.json", {_method: 'delete'}, =>
      @root.memberships.remove @

  findLayerMembership: (layer) =>
    lm = @layers().filter((x) -> x.layerId() == layer.id())
    if lm.length > 0 then lm[0] else null

  keyPress: (field, event) =>
    switch event.keyCode
      when 13
        @createCustomPermissionForSite()
      when 27 then @exit()
      else true

  saveCustomSitePermissions: =>
    $.post "/collections/#{@collectionId()}/sites_permission", sites_permission: user_id: @userId(), read: SiteCustomPermission.summarizeRead(@sitesWithCustomPermissions()), write: SiteCustomPermission.summarizeWrite(@sitesWithCustomPermissions())

  save: =>
  exit: =>
