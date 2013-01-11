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
              when 'data_errors'
                # In this case errorColumns contains an object with the following structure:
                # {description: “Error description”, column: 1, rows: [1, 3, 5, 6]}
                error = errorColumns
                error_description.columns = [error.column]
                error_description.description = "#{error.rows.length} rows does not match column number #{error.column} type. Error message: '#{error.description}'"
                error_description.more_info = "Rows numbers: #{error.rows.join(',')}"
            errorsForUI.push(error_description)
      errorsForUI