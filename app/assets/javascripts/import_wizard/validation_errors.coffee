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
              when'duplicated_label'
                error_description.description = "Duplicated column with label #{errorId}"
              else
                error_description.description = "TBD"
            error_description.more_info = "Column numbers: #{errorColumns.join(',')}"
            errorsForUI.push(error_description)
      errorsForUI