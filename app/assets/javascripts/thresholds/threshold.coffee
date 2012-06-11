onThresholds ->
  class @Threshold
    constructor: (data) ->
      @id = ko.observable data?.id
      @collectionId = data?.collection_id
      @isSomeSites = ko.observable("true")
      @isAllOfConditions = ko.observable("true") 
      @ord = ko.observable data?.ord
      @color = ko.observable(data?.color ? '#ff0000')
      @conditions = ko.observableArray $.map(data?.conditions ? [], (condition) -> new Condition(condition))
      @error = ko.computed =>
        return "the threshold must have at least one condition" if @conditions().length is 0
        for condition, i in @conditions()
          return "condition ##{i+1} #{condition.error()}" unless condition.valid()
      @valid = ko.computed => not @error()?

    addNewCondition: =>
      condition = new Condition()
      @conditions.push condition
      condition

    removeCondition: (condition) =>
      @conditions.remove condition

    isLastCondition: (condition) ->
      @conditions().length - 1 == @conditions().indexOf condition

    setOrder: (ord, callback) ->
      @ord ord
      $.post "/collections/#{@collectionId}/thresholds/#{@id()}/set_order.json", { ord: ord }, callback

    toJSON: =>
      id: @id()
      color: @color()
      conditions: $.map(@conditions(), (condition) -> condition.toJSON())
      ord: @ord()
