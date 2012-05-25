onCollections ->

  class @Option
    constructor: (data) ->
      @id = ko.observable(data?.id)
      @code = ko.observable(data?.code)
      @label = ko.observable(data?.label)
      @selected = ko.observable(false)
