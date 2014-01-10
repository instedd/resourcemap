onCollections ->

  class @Layer
    constructor: (data) ->
      newValueForField = (esCode) ->
        window.model.newSiteProperties[esCode]

      @name = data?.name

      @fields = $.map data.fields, (x) =>
        new Field x, newValueForField

      @expanded = ko.observable(true)

    toggleExpand: =>
      @expanded(!@expanded())
