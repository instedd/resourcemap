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
          @sites $.map(data, (x) -> new Site(x))
          callback() if callback

    findSiteById: (id) =>
      for i, site of @sites()
        return site if site.id() == id

        subsite = site.findSiteById(id)
        return subsite if subsite

      null

    addSite: (site) =>
      @fetchSites => @sites().push(site)

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

  class Site extends SitesContainer
    constructor: (data) ->
      super
      @class = 'Site'

    sitesUrl: -> "/sites/#{@id()}/root_sites"

  class CollectionViewModel
    constructor: ->
      self = this

      @collections = ko.observableArray $.map(initialCollections, (x) -> new Collection(x))
      @selectedCollection = ko.observable()
      @creatingCollectionFolder = ko.observable()
      @creatingCollectionFolderSite = ko.observable()
      @newFolderName = ko.observable('')

      @root = ko.computed ->
        !self.selectedCollection() && !self.creatingCollectionFolder()

      @selectedCollection.subscribe (newValue) ->
        newValue.fetchSites() if newValue

      Sammy( ->
        @get '#:collection', ->
          self.creatingCollectionFolder null
          self.selectedCollection self.findCollectionById(parseInt this.params.collection)

        @get '#:collection/folder/new', ->
          self.selectedCollection null
          self.creatingCollectionFolder self.findCollectionById(parseInt this.params.collection)
          self.newFolderName ""

        @get '#:collection/:site/folder/new', ->
          self.selectedCollection null
          self.creatingCollectionFolder self.findCollectionById(parseInt this.params.collection)
          self.creatingCollectionFolderSite self.creatingCollectionFolder().findSiteById(parseInt this.params.site)
          self.newFolderName ""

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

    enterCreateFolder: (parent) =>
      if parent.class == 'Site'
        location.hash = "#{@selectedCollection().id()}/#{parent.id()}/folder/new"
      else
        location.hash = "#{@selectedCollection().id()}/folder/new"

    exitCreateFolder: =>
      location.hash = "#{@creatingCollectionFolder().id()}"

    createFolder: =>
      self = this
      site = {name: @newFolderName(), folder: true}
      site.parent_id = @creatingCollectionFolderSite().id() if @creatingCollectionFolderSite()
      $.post "/collections/#{@creatingCollectionFolder().id()}/sites", {site: site}, (data) ->
        if self.creatingCollectionFolderSite()
          self.creatingCollectionFolderSite().addSite(new Site data)
        else
          self.creatingCollectionFolder().addSite(new Site data)
        self.enterCollection self.creatingCollectionFolder()

  ko.applyBindings new CollectionViewModel
