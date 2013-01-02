describe 'ValidationErrors', ->
  beforeEach ->
    window.runOnCallbacks 'importWizard'

  it 'should evaluate if there are errors in @errors', ->
    errors = {duplicated_code:[], duplicated_label:[], existing_label:[], existing_code:[], usage_missing:[], duplicated_usage: [], data_errors: []}
    empty_val_errors = new ValidationErrors(errors)
    expect(empty_val_errors.hasErrors()).toBe(false)
    errors.duplicated_code = {'text_column':[0, 1]}
    val_errors = new ValidationErrors(errors)
    expect(val_errors.hasErrors()).toBe(true)

  for error_type in ['code', 'label']
    it "should generate redeable errors for duplicated #{error_type}", ->
      errors = {duplicated_code:[], duplicated_label:[], existing_label:[], existing_code:[], usage_missing:[], duplicated_usage: [], data_errors: []}
      if error_type == 'code'
        errors.duplicated_code = {'text_column':[0, 1]}
      if error_type == 'label'
        errors.duplicated_label = {'text_column':[0, 1]}
      val_errors = new ValidationErrors(errors)
      redeable_errors = val_errors.errorsForUI()
      expect(redeable_errors.length).toBe(1)
      first_error = redeable_errors[0]
      expect(first_error.error_kind).toBe("duplicated_#{error_type}")
      expect(first_error.description).toBe("Duplicated column with #{error_type} text_column")
      expect(first_error.columns).toEqual([0,1])
      expect(first_error.more_info).toEqual('Column numbers: 0,1')

