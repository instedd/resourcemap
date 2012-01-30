@initCollections = (initialCollections) ->
  class SitesContainer
    constructor: (data) ->
      @id = ko.observable data.id
      @name = ko.observable data.name
      @sites = ko.observableArray()
      @sitesInitialized = false
      @expanded = ko.observable false

    fetchSites: (callback) =>
      if @sitesInitialized
        callback() if callback
      else
        @sitesInitialized = true
        $.get @sitesUrl(), {}, (data) =>
          @sites $.map(data, (x) => new Site(x, this))
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

    expand: =>
      @fetchSites()
      @expanded true

    collapse: =>
      @expanded false

  class Collection extends SitesContainer
    constructor: (data) ->
      super
      @class = 'Collection'

    sitesUrl: -> "/collections/#{@id()}/sites"

    level: -> 0

  class Site extends SitesContainer
    constructor: (data, parent) ->
      super
      @class = 'Site'
      @parent = parent
      @selected = ko.observable()

    sitesUrl: -> "/sites/#{@id()}/root_sites"

    level: =>
      @parent.level() + 1

  class CollectionViewModel
    constructor: ->
      self = this

      @collections = ko.observableArray $.map(initialCollections, (x) -> new Collection(x))
      @selectedCollection = ko.observable()
      @selectedSite = ko.observable()
      @creatinGroupCollection = ko.observable()
      @groupName = ko.observable('')

      @root = ko.computed ->
        !self.selectedCollection() && !self.creatinGroupCollection()

      @selectedCollection.subscribe (newValue) ->
        newValue.fetchSites() if newValue

      Sammy( ->
        @get '#:collection', ->
          self.creatinGroupCollection null
          self.selectedCollection self.findCollectionById(parseInt this.params.collection)
          self.groupName ""

        @get '#:collection/group/new', ->
          self.selectedCollection null
          self.creatinGroupCollection self.findCollectionById(parseInt this.params.collection)
          self.groupName ""

        @get '#:collection/:site/group/new', ->
          self.selectedCollection null
          self.creatinGroupCollection self.findCollectionById(parseInt this.params.collection)
          self.selectedSite self.creatinGroupCollection().findSiteById(parseInt this.params.site)
          self.selectedSite().selected(true)
          self.groupName ""

        @get '', ->
          self.selectedCollection(null)
      ).run()

    findCollectionById: (id) =>
      (x for x in @collections() when x.id() == id)[0]

    enterRoot: ->
      location.hash = ''

    enterCollection: (collection) ->
      location.hash = "#{collection.id()}"

    editCollection: (collection) ->
      window.location = "/collections/#{collection.id()}"

    enterCreateCollection: ->
      window.location = "/collections/new"

    enterCreateGroup: =>
      if @selectedSite()
        location.hash = "#{@selectedCollection().id()}/#{@selectedSite().id()}/group/new"
      else
        location.hash = "#{@selectedCollection().id()}/group/new"

    exitCreateGroup: =>
      location.hash = "#{@creatinGroupCollection().id()}"

    createGroup: =>
      self = this
      site = {name: @groupName(), folder: true}
      site.parent_id = @selectedSite().id() if @selectedSite()
      $.post "/collections/#{@creatinGroupCollection().id()}/sites", {site: site}, (data) =>
        if @selectedSite()
          if @selectedSite().sitesInitialized
            @selectedSite().sites().push(new Site(data, @selectedSite()))
        else
          @creatinGroupCollection().addSite(new Site(data, @creatinGroupCollection()))
        @enterCollection @creatinGroupCollection()

    selectSite: (site) =>
      if @selectedSite() == site
        @selectedSite().selected(false)
        @selectedSite(null)
      else
        @selectedSite().selected(false) if @selectedSite()
        @selectedSite(site)
        @selectedSite().selected(true)

  ko.applyBindings new CollectionViewModel
