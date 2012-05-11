onCollections ->

  class @Option
    constructor: (data) ->
      @code = ko.observable(data?.code)
      @label = ko.observable(data?.label)
      @selected = ko.observable(false)
