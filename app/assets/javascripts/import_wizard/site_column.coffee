onImportWizard ->
  class @SiteColumn
    constructor: (data) ->
      @value = data.value
      #This value will be replaced by the data_error for each field obtained from main_view_model_errors
      @error = ''
