onImportWizard ->
  class @ValidationErrors
    constructor: (data) ->
      @errors = data

    hasErrors: =>
      for errorKey,errorValue of @errors
        return true unless $.isEmptyObject(errorValue)
      return false

    toIndex1BasedSentence: (index_array) =>
      console.log(index_array)
      index_array = $.map index_array, (e) => e+1
      window.toSentence(index_array)

    errorsForUI: =>
      errorsForUI = []
      for errorType,errors of @errors
        if !$.isEmptyObject(errors)
          for errorId, errorColumns of errors
            error_description = {error_kind: errorType, columns: errorColumns}
            switch errorType
              when 'duplicated_code'
                error_description.description = "There is more than one column with code #{errorId}."
                error_description.more_info = "Columns #{@toIndex1BasedSentence(errorColumns)} have code #{errorId}. To fix this issue, leave only one with that code and modify the rest."
              when 'duplicated_label'
                error_description.description = "There is more than one column with name #{errorId}."
                error_description.more_info = "Columns #{@toIndex1BasedSentence(errorColumns)} have name #{errorId}. To fix this issue, leave only one with that name and modify the rest."
              when 'duplicated_usage'
                field = window.model.findField(errorId)
                if field
                  duplicated = "field #{field.name}"
                else
                  duplicated = errorId
                error_description.description = "Only one column can be the #{duplicated}."
                error_description.more_info = "Columns #{@toIndex1BasedSentence(errorColumns)} are marked as #{duplicated}. To fix this issue, leave only one of them assigned as '#{duplicated}' and modify the rest."
              when 'existing_code'
                error_description.description = "There is already a field with code #{errorId} in this collection."
                error_description.more_info = "Columns #{@toIndex1BasedSentence(errorColumns)} have code #{errorId}. To fix this issue, change all their codes."
              when 'existing_label'
                error_description.description = "There is already a field with name #{errorId} in this collection."
                error_description.more_info = "Columns #{@toIndex1BasedSentence(errorColumns)} have name #{errorId}. To fix this issue, change all their names."
              when 'hierarchy_field_found'
                error_description.description = "Hierarchy fields can only be created via web in the Layers page."
                error_description.more_info = "Column numbers: #{@toIndex1BasedSentence(errorColumns)}."
              when 'data_errors'
                # In this case errorColumns contains an object with the following structure:
                # {description: “Error description”, column: 1, rows: [1, 3, 5, 6], example: "Hint", type: 'numeric}
                error = errorColumns
                error_description.columns = [error.column]
                error_description.description = "There are #{error.rows.length} errors in column #{error.column + 1}."
                error_description.more_info = "#{error.description} To fix this, either change the column's type or edit your CSV so that all rows hold valid #{error.type}."
                if error.example
                  error_description.more_info = error_description.more_info + " " + error.example
                error_description.more_info = error_description.more_info + " The invalid #{error.type} are in the following rows: #{@toIndex1BasedSentence(error.rows)}."
            errorsForUI.push(error_description)
      errorsForUI
