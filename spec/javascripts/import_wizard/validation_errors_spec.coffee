describe 'ValidationErrors', ->
  beforeEach ->
    window.runOnCallbacks 'importWizard'

  it 'should evaluate if there are errors in @errors', ->
    errors = {duplicated_code:[], duplicated_label:[], existing_label:[], existing_code:[], usage_missing:[], duplicated_usage: [], data_errors: []}
    empty_val_errors = new ValidationErrors(errors)
    expect(empty_val_errors.hasErrors()).toBe(false)
    errors.data_errors = [{description:'Invalid numeric value in n field', column:3, rows:[0, 1, 2, 3, 4, 5, 6]}]
    val_errors = new ValidationErrors(errors)
    expect(empty_val_errors.hasErrors()).toBe(true)


