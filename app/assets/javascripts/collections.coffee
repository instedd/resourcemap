@initCollections = (initialCollections) ->
  class SitesContainer
    constructor: (data) ->
      @id = ko.observable data?.id
      @name = ko.observable data?.name
      @sites = ko.observableArray()
      @sitesInitialized = false
      @expanded = ko.observable false

    fetchSites: (callback) =>
      if @sitesInitialized
        callback() if callback
      else
        @sitesInitialized = true
        $.get @sitesUrl(), {}, (data) =>
          @sites $.map(data, (x) => new Site(this, x))
          callback() if callback

    findSiteById: (id) =>
      for i, site of @sites()
        return site if site.id() == id

        subsite = site.findSiteById(id)
        return subsite if subsite

      null

    addSite: (site) =>
      @fetchSites =>
        @sites().push(site)

    toggle: =>
      @fetchSites() unless @expanded()
      @expanded(!@expanded())

  class Collection extends SitesContainer
    constructor: (data) ->
      super
      @class = 'Collection'

    sitesUrl: -> "/collections/#{@id()}/sites"

    level: -> 0

  class Site extends SitesContainer
    constructor: (parent, data) ->
      super
      @class = 'Site'
      @parent = parent
      @selected = ko.observable()
      @id = ko.observable data?.id
      @parent_id = ko.observable data?.parent_id
      @folder = ko.observable data?.folder
      @name = ko.observable data?.name

    sitesUrl: -> "/sites/#{@id()}/root_sites"

    level: =>
      @parent.level() + 1

    toJSON: =>
      id: @id()
      parent_id: @parent_id()
      folder: @folder()
      name: @name()

  class CollectionViewModel
    constructor: ->
      self = this

      @collections = ko.observableArray $.map(initialCollections, (x) -> new Collection(x))
      @currentCollection = ko.observable()
      @currentParent = ko.observable()
      @currentSite = ko.observable()
      @selectedSite = ko.observable()

      @currentCollection.subscribe (newValue) ->
        newValue.fetchSites() if newValue

      Sammy( ->
        @get '#:collection', ->
          self.currentCollection self.findCollectionById(parseInt this.params.collection)

        @get '', ->
          self.currentCollection(null)
      ).run()

    findCollectionById: (id) =>
      (x for x in @collections() when x.id() == id)[0]

    goToRoot: ->
      location.hash = ''

    enterCollection: (collection) ->
      location.hash = "#{collection.id()}"

    editCollection: (collection) ->
      window.location = "/collections/#{collection.id()}"

    createCollection: ->
      window.location = "/collections/new"

    createGroup: =>
      parent = if @selectedSite() then @selectedSite() else @currentCollection()
      @currentSite(new Site(parent, folder: true, parent_id: @selectedSite()?.id()))

    createSite: =>
      parent = if @selectedSite() then @selectedSite() else @currentCollection()
      @currentSite(new Site(parent, parent_id: @selectedSite()?.id()))

    exitSite: =>
      @currentSite(null)

    editSite: (site) =>
      @currentSite(site)

    saveSite: =>
      callback = (data) =>
        if !@currentSite().id()
          @currentSite().id(data.id)
          if @selectedSite()
            if @selectedSite().sitesInitialized
              @selectedSite().sites.push(@currentSite())
          else
            @currentCollection().addSite(@currentSite())
        @currentSite(null)

      json = {site: @currentSite().toJSON()}

      if @currentSite().id()
        json._method = 'put'
        $.post "/collections/#{@currentCollection().id()}/sites/#{@currentSite().id()}.json", json, callback
      else
        $.post "/collections/#{@currentCollection().id()}/sites", json, callback

    selectSite: (site) =>
      if @selectedSite() == site
        @selectedSite().selected(false)
        @selectedSite(null)
      else
        @selectedSite().selected(false) if @selectedSite()
        @selectedSite(site)
        @selectedSite().selected(true)
      site.toggle()

  ko.applyBindings new CollectionViewModel
