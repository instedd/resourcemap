onReminders ->
  class @Site
    constructor: (data) ->
      @id = data?.id
      @name = data?.name

    toJSON: =>
      id: @id
      name: @name
