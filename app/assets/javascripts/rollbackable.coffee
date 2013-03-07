class @Rollbackable
  @constructor: (data) ->
    @update_function = @update

    @update = (json_data) ->
      @update_function json_data
      @commit()

    @update data

  @commit: ->
    @lastVersion = @toJSON()

  @rollback: ->
    @update @lastVersion
