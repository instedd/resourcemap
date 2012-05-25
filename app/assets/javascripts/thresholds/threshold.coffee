onThresholds ->
  class @Threshold
    constructor: (data) ->
      @id = ko.observable data?.id
      @conditions = ko.observableArray $.map(data?.conditions ? [], (condition) -> new Condition(condition))
      @ord = ko.observable data?.ord
      @color = ko.observable(data?.color ? '#ff0000')
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

    isFirstCondition: (condition) ->
      0 == @conditions().indexOf condition

    isLastCondition: (condition) ->
      @conditions().length - 1 == @conditions().indexOf condition

    toJSON: =>
      id: @id()
      color: @color()
      conditions: $.map(@conditions(), (condition) -> condition.toJSON())
      ord: @ord()
