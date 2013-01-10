onImportWizard ->
  class @ValidationErrors
    constructor: (data) ->
      @errors = data

    hasErrors: =>
      for errorKey,errorValue of @errors
        return true unless $.isEmptyObject(errorValue)
      return false

    errorsForUI: =>
      errorsForUI = []
      for errorType,errors of @errors
        if !$.isEmptyObject(errors)
          for errorId, errorColumns of errors
            error_description = {error_kind: errorType, columns: errorColumns}
            switch errorType
              when 'duplicated_code'
                error_description.description = "Duplicated column with code #{errorId}"
                error_description.more_info = "Column numbers: #{errorColumns.join(',')}"
              when 'duplicated_label'
                error_description.description = "Duplicated column with label #{errorId}"
                error_description.more_info = "Column numbers: #{errorColumns.join(',')}"
              when 'duplicated_usage'
                field = window.model.findField(errorId)
                if field
                  error_description.description = "Duplicated column with usage 'existing field' #{field.name}"
                else
                  error_description.description = "Duplicated column with usage #{errorId}"
                error_description.more_info = "Column numbers: #{errorColumns.join(',')}"
              when 'existing_code'
                error_description.description = "There is an existing field with code #{errorId} in your collection"
                error_description.more_info = "Column numbers: #{errorColumns.join(',')}"
              when 'existing_label'
                error_description.description = "There is an existing field with label #{errorId} in your collection"
                error_description.more_info = "Column numbers: #{errorColumns.join(',')}"
              when 'hierarchy_field_found'
                error_description.description = "Hierarchy fields can only be created via web in the Layers page"
                error_description.more_info = "Column numbers: #{errorColumns.join(',')}"
              else
                error_description.description = "TBD"
                error_description.more_info = "TBD"

            errorsForUI.push(error_description)
      errorsForUI