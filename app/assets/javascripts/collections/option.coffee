onCollections ->

  class @Option
    constructor: (data) ->
      @id = data?.id
      @code = data?.code
      @label = data?.label
      @selected = ko.observable(false)
