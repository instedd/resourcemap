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

  check_duplicated_field_assertion = (error_type, column_name, proc) ->
    errors = {duplicated_code:[], duplicated_label:[], existing_label:[], existing_code:[], usage_missing:[], duplicated_usage: [], data_errors: []}
    proc(errors)
    val_errors = new ValidationErrors(errors)
    redeable_errors = val_errors.errorsForUI()
    expect(redeable_errors.length).toBe(1)
    first_error = redeable_errors[0]
    expect(first_error.error_kind).toBe("duplicated_#{error_type}")
    expect(first_error.description).toBe("Duplicated column with #{error_type} #{column_name}")
    expect(first_error.columns).toEqual([0,1])
    expect(first_error.more_info).toEqual('Column numbers: 0,1')

  check_existing_field_assertion = (error_type, column_name, proc) ->
    errors = {duplicated_code:[], duplicated_label:[], existing_label:[], existing_code:[], usage_missing:[], duplicated_usage: [], data_errors: []}
    proc(errors)
    val_errors = new ValidationErrors(errors)
    redeable_errors = val_errors.errorsForUI()
    expect(redeable_errors.length).toBe(1)
    first_error = redeable_errors[0]
    expect(first_error.error_kind).toBe("existing_#{error_type}")
    expect(first_error.description).toBe("The is an existing field with #{error_type} #{column_name} in your collection")
    expect(first_error.columns).toEqual([0,1])
    expect(first_error.more_info).toEqual('Column numbers: 0,1')

  it "should generate redeable errors for duplicated code", ->
    proc_duplicated_code = (errors) -> errors.duplicated_code = {text_column: [0, 1]}
    check_duplicated_field_assertion('code', 'text_column', proc_duplicated_code)

  it "should generate redeable errors for duplicated label", ->
    proc_duplicated_label = (errors) -> errors.duplicated_label = {text_column: [0, 1]}
    check_duplicated_field_assertion('label', 'text_column', proc_duplicated_label)

  it "should generate redeable errors for duplicated usage for default usages (lat, lng, name or id)", ->
    proc_duplicated_usage = (errors, column_name) -> errors.duplicated_usage = {lat: [0, 1]}
    check_duplicated_field_assertion('usage', 'lat', proc_duplicated_usage)

  it "should generate redeable errors for existing code", ->
    proc_existing_code = (errors, column_name) -> errors.existing_code = {text_column: [0, 1]}
    check_existing_field_assertion('code', 'text_column', proc_existing_code)

  it "should generate redeable errors for existing label", ->
    proc_existing_label = (errors, column_name) -> errors.existing_label = {text_column: [0, 1]}
    check_existing_field_assertion('label', 'text_column', proc_existing_label)

