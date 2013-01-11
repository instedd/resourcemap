describe 'ValidationErrors', ->
  beforeEach ->
    window.runOnCallbacks 'importWizard'
    window.model = new MainViewModel
    layers = [{id: 1, name: "layer 1", fields: [{id: 1, name: "field 1", kind: 'text', code: 'field1'}] }]
    columns =[{name: "field 1", usage: "name"}]
    window.model.initialize(1, layers, columns)

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
    expect(first_error.description).toBe("There is an existing field with #{error_type} #{column_name} in your collection")
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

  it "should generate redeable errors for duplicated usage for existing_field", ->
    proc_duplicated_usage = (errors, column_name) -> errors.duplicated_usage = {'1': [0, 1]}
    check_duplicated_field_assertion('usage', "'existing field' field 1", proc_duplicated_usage)

  it "should generate redeable errors for existing code", ->
    proc_existing_code = (errors, column_name) -> errors.existing_code = {text_column: [0, 1]}
    check_existing_field_assertion('code', 'text_column', proc_existing_code)

  it "should generate redeable errors for existing label", ->
    proc_existing_label = (errors, column_name) -> errors.existing_label = {text_column: [0, 1]}
    check_existing_field_assertion('label', 'text_column', proc_existing_label)

  it "should generate redeable errors for hierarchy field found", ->
    errors = {hierarchy_field_found:[]}
    errors.hierarchy_field_found = {new_hierarchy_columns: [1, 2, 3]}
    val_errors = new ValidationErrors(errors)
    redeable_errors = val_errors.errorsForUI()
    expect(redeable_errors.length).toBe(1)
    first_error = redeable_errors[0]
    expect(first_error.error_kind).toBe("hierarchy_field_found")
    expect(first_error.description).toBe("Hierarchy fields can only be created via web in the Layers page")
    expect(first_error.columns).toEqual([1,2,3])
    expect(first_error.more_info).toEqual('Column numbers: 1,2,3')

  it "should generate redeable errors data errors", ->
    errors = {data_errors:[]}
    errors.data_errors = [{description: "Invalid option in many field", column: 4, rows: [1,2]}, {description: "Invalid numeric value in text field", column: 1, rows: [1]}]
    val_errors = new ValidationErrors(errors)
    redeable_errors = val_errors.errorsForUI()
    expect(redeable_errors.length).toBe(2)
    first_error = redeable_errors[0]
    expect(first_error.error_kind).toBe("data_errors")
    expect(first_error.description).toBe("2 rows does not match column number 4 type. Error message: 'Invalid option in many field'")
    expect(first_error.columns).toEqual([4])
    expect(first_error.more_info).toEqual('Rows numbers: 1,2')
    second_error = redeable_errors[1]
    expect(second_error.error_kind).toBe("data_errors")
    expect(second_error.description).toBe("1 rows does not match column number 1 type. Error message: 'Invalid numeric value in text field'")
    expect(second_error.columns).toEqual([1])
    expect(second_error.more_info).toEqual('Rows numbers: 1')

