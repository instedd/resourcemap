onImportWizard ->
  class @MainViewModel
    initialize: (collectionId, layers, columns, field_kinds) ->
      @field_kinds = _.filter field_kinds, (k) -> k != 'hierarchy'

      @collectionId = collectionId
      @layers = $.map(layers, (x) -> new Layer(x))

      @columns = ko.observableArray $.map(columns,  (x, index) -> new Column(x, index))
      @visibleColumns = ko.observableArray @columns()
      @sites = ko.observableArray()
      @sitesCount = ko.observable(0)
      @visibleSites = ko.observableArray()
      @showingColumns = ko.observable('all')

      @selectedColumn = ko.observable()
      @loadUsages(@selectedColumn())

      @hasId = ko.computed =>
        window.arrayAny(@columns(), (c) => c.usage() == 'id')

      @error = ko.computed =>
        window.arrayAny(@sites(), (s) => window.arrayAny(s, (f) => f.error)) || window.arrayAny(@columns(), (c) => c.errors().length > 0)

      @validationErrors = ko.observable()

      @validationErrors.subscribe  =>
        @recalculateErrorsForColumns()

      @valid = ko.computed => !@error()
      @importing = ko.observable false
      @importError = ko.observable false

    recalculateErrorsForColumns: =>
      for column in @columns()
        new_errors = @validationErrors().errorsForColumn(column.index)
        column.errors(new_errors)

    loadVisibleSites: =>
      visible_columns_indexes = $.map(@visibleColumns(), (c) -> c.index)
      @visibleSites([])
      for site in @sites()
          new_site_columns = $.grep site.siteColumns, (s, i) ->
            i in visible_columns_indexes
          @visibleSites.push(new Site(new_site_columns))

    loadSites: (preview) =>
      # This method is called after server validations, after changing a column usage or after requesting the sites for the first time.
      sites = $.map(preview.sites, (x) -> new Site(x))
      @sites(sites)
      @sitesCount(preview.sites_count)
      @validationErrors(new ValidationErrors(@columns, preview.errors))
      @loadVisibleSites()

    loadUsages: (column) =>
      @usages = [new Usage('New field', 'new_field')]
      if @layers.length > 0
        @usages.push(new Usage('Existing field', 'existing_field'))
      @usages.push(new Usage('Name', 'name'))
      @usages.push(new Usage('Latitude', 'lat'))
      @usages.push(new Usage('Longitude', 'lng'))
      @usages.push(new Usage('Ignore', 'ignore'))
      @usages.push(new Usage('resmap-id', 'id'))

      @selectableUsagesForAdmins = @usages.slice(0)
      # Non admins can't create new fields
      @selectableUsagesForNonAdmins = @usages.slice(1)

    findLayer: (id) =>
      (layer for layer in @layers when layer.id == id)[0]

    findField: (id) =>
      for layer in @layers
        field = layer.findField(id) unless field
      field

    identifierFields: =>
      identifierFields = []
      for layer in @layers
        identifierFields = identifierFields.concat layer.identifierFields()
      identifierFields.concat(new Usage("Internal ResourceMap ID", "resmap-id"))

    selectColumn: (column) =>
      @loadUsages(column)
      @selectedColumn(column)
      true

    blockTable: =>
      $('#preview').block({
        message: '<p class="loading box" id="validating_msg">Validating</p>'
      })
      $(".blockOverlay").addClass("box")
      $(".show_column_options").find("input").attr('disabled', 'disabled')

    unblockTable: =>
      $(".show_column_options").find("input").removeAttr('disabled')
      if $('.error_description').length > 0
        $(window).scrollTop($('.error_description').position().top)
      $('#preview').unblock()

    validateSites: =>
      @blockTable()
      if @columns
        $.post "/collections/#{@collectionId}/import_wizard/validate_sites_with_columns.json", {columns: JSON.stringify(@columns())}, (preview) =>
          @loadSites(preview)
          @unblockTable()

    showAllColumns: =>
      @visibleColumns(@columns())
      @visibleSites(@sites())
      @showingColumns('all')

    showColumnsWithErrors: =>
      with_errors = $.grep @columns(), (c, i) ->
        c.errors().length > 0
      @visibleColumns(with_errors)
      @loadVisibleSites()
      @showingColumns('with_errors')

    showNewColumns: =>
      new_columns = $.grep @columns(), (c, i) ->
        c.usage() == 'new_field'
      @visibleColumns(new_columns)
      @loadVisibleSites()
      @showingColumns('new')

    showExistingColumns: =>
      existing_columns = $.grep @columns(), (c, i) ->
        c.usage() == 'existing_field'
      @visibleColumns(existing_columns)
      @loadVisibleSites()
      @showingColumns('existing')

    startImport: =>
      @importing(true)
      columns = $.map(@columns(), (x) -> x.toJSON())
      $.ajax "/collections/#{@collectionId}/import_wizard/execute.json",
        type: 'POST'
        data: {columns: columns},
        success: =>
          window.location = "/collections/#{@collectionId}/import_wizard/import_in_progress"
        error: =>
          @importing(false)
          @importError(true)
