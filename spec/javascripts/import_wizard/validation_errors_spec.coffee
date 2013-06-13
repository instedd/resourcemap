describe 'ImportWizard', ->
  window.runOnCallbacks 'importWizard'

  describe 'ValidationErrors', ->
    beforeEach ->
      window.model = new MainViewModel
      layers = [{id: 1, name: "layer 1", fields: [{id: 1, name: "field 1", kind: 'text', code: 'field1'}] }]
      columns =[{header: "field 1", use_as: "name"}]
      window.model.initialize(1, layers, columns)

    it 'should evaluate if there are errors in @errors', ->
      errors = {duplicated_code:[], duplicated_label:[], existing_label:[], existing_code:[], duplicated_usage: [], data_errors: []}
      empty_val_errors = new ValidationErrors(errors)
      expect(empty_val_errors.hasErrors()).toBe(false)
      errors.duplicated_code = {'text_column':[0, 1]}
      val_errors = new ValidationErrors(errors)
      expect(val_errors.hasErrors()).toBe(true)

    check_duplicated_field_assertion = (error_type, column_name, proc) ->
      errors = {duplicated_code:[], duplicated_label:[], existing_label:[], existing_code:[], duplicated_usage: [], data_errors: []}
      proc(errors)
      val_errors = new ValidationErrors(errors)
      redeable_errors = val_errors.processErrors()
      expect(redeable_errors.length).toBe(1)
      first_error = redeable_errors[0]
      if error_type == 'name'
        expect(first_error.error_kind).toBe("duplicated_label")
      else
        expect(first_error.error_kind).toBe("duplicated_#{error_type}")
      expect(first_error.description).toBe("There is more than one column with #{error_type} '#{column_name}'.")
      expect(first_error.columns).toEqual([0,1])
      expect(first_error.more_info).toEqual("Columns 1 and 2 have the same #{error_type}. To fix this issue, leave only one with that #{error_type} and modify the rest.")

    check_existing_field_assertion = (error_type, column_name, proc) ->
      errors = {duplicated_code:[], duplicated_label:[], existing_label:[], existing_code:[], duplicated_usage: [], data_errors: []}
      proc(errors)
      val_errors = new ValidationErrors(errors)
      redeable_errors = val_errors.processErrors()
      expect(redeable_errors.length).toBe(1)
      first_error = redeable_errors[0]
      if error_type == 'name'
        expect(first_error.error_kind).toBe("existing_label")
      else
        expect(first_error.error_kind).toBe("existing_#{error_type}")

      expect(first_error.description).toBe("There is already a field with #{error_type} #{column_name} in this collection.")
      expect(first_error.columns).toEqual([0,1])
      expect(first_error.more_info).toEqual("Columns 1 and 2 have #{error_type} #{column_name}. To fix this issue, change all their #{error_type}s.")

    check_duplicated_usage = (error_type, column_name, proc) ->
      errors = {duplicated_code:[], duplicated_label:[], existing_label:[], existing_code:[], duplicated_usage: [], data_errors: []}
      proc(errors)
      val_errors = new ValidationErrors(errors)
      redeable_errors = val_errors.processErrors()
      expect(redeable_errors.length).toBe(1)
      first_error = redeable_errors[0]

      expect(first_error.error_kind).toBe("duplicated_#{error_type}")
      expect(first_error.description).toBe("Only one column can be the #{column_name}.")
      expect(first_error.columns).toEqual([0,1])
      expect(first_error.more_info).toEqual("Columns 1 and 2 are marked as #{column_name}. To fix this issue, leave only one of them assigned as '#{column_name}' and modify the rest.")

    check_missing_element_assertion_plural = (missing_element, proc) ->
      errors = {missing_label:[], missing_code: []}
      proc(errors)
      val_errors = new ValidationErrors(errors)
      redeable_errors = val_errors.processErrors()
      expect(redeable_errors.length).toBe(1)
      first_error = redeable_errors[0]
      expect(first_error.error_kind).toBe("missing_#{missing_element}")
      if missing_element == 'label'
        missing_element = 'name'
      expect(first_error.description).toBe("Columns 2, 3 and 4 are missing the field's #{missing_element}.")
      expect(first_error.columns).toEqual([1,2,3])
      expect(first_error.more_info).toEqual("Columns 2, 3 and 4 are missing the field's #{missing_element}, which is required for new fields. To fix this issue, add a #{missing_element} for each of these columns.")

    check_missing_element_assertion = (missing_element, proc) ->
      errors = {missing_label:[], missing_code: []}
      proc(errors)
      val_errors = new ValidationErrors(errors)
      redeable_errors = val_errors.processErrors()
      expect(redeable_errors.length).toBe(1)
      first_error = redeable_errors[0]
      expect(first_error.error_kind).toBe("missing_#{missing_element}")
      if missing_element == 'label'
        missing_element = 'name'
      expect(first_error.description).toBe("Column 2 is missing the field's #{missing_element}.")
      expect(first_error.columns).toEqual([1])
      expect(first_error.more_info).toEqual("Column 2 is missing the field's #{missing_element}, which is required for new fields. To fix this issue, add a #{missing_element} for this column.")

    it "should generate redeable errors for duplicated code", ->
      proc_duplicated_code = (errors) -> errors.duplicated_code = {text_column: [0, 1]}
      check_duplicated_field_assertion('code', 'text_column', proc_duplicated_code)

    it "should generate redeable errors for duplicated label", ->
      proc_duplicated_label = (errors) -> errors.duplicated_label = {text_column: [0, 1]}
      check_duplicated_field_assertion('name', 'text_column', proc_duplicated_label)

    it "should generate redeable errors for existing code", ->
      proc_existing_code = (errors, column_name) -> errors.existing_code = {text_column: [0, 1]}
      check_existing_field_assertion('code', 'text_column', proc_existing_code)

    it "should generate redeable errors for existing label", ->
      proc_existing_label = (errors, column_name) -> errors.existing_label = {text_column: [0, 1]}
      check_existing_field_assertion('name', 'text_column', proc_existing_label)

    it "should generate redeable errors for duplicated usage for default usages (lat, lng, name or id)", ->
      proc_duplicated_usage = (errors, column_name) -> errors.duplicated_usage = {lat: [0, 1]}
      check_duplicated_usage('usage', 'lat', proc_duplicated_usage)

    it "should generate redeable errors for duplicated usage for existing_field", ->
      proc_duplicated_usage = (errors, column_name) -> errors.duplicated_usage = {'1': [0, 1]}
      check_duplicated_usage('usage', "field field 1", proc_duplicated_usage)

    it "should generate redeable errors for hierarchy field found", ->
      errors = {hierarchy_field_found:[]}
      errors.hierarchy_field_found = {new_hierarchy_columns: [1, 2, 3]}
      val_errors = new ValidationErrors(errors)
      redeable_errors = val_errors.processErrors()
      expect(redeable_errors.length).toBe(1)
      first_error = redeable_errors[0]
      expect(first_error.error_kind).toBe("hierarchy_field_found")
      expect(first_error.description).toBe("Hierarchy fields can only be created via web in the Layers page.")
      expect(first_error.columns).toEqual([1,2,3])
      expect(first_error.more_info).toEqual('Column numbers: 2, 3 and 4.')

    it "should generate redeable errors for more than one label missing for new fields", ->
      proc_missing_label = (errors, column_name) -> errors.missing_label = {columns:[1, 2, 3]}
      check_missing_element_assertion_plural('label', proc_missing_label)

    it "should generate redeable errors for more than one code missing for new fields", ->
      proc_missing_code = (errors, column_name) -> errors.missing_code = {columns:[1, 2, 3]}
      check_missing_element_assertion_plural('code', proc_missing_code)

    it "should generate redeable errors one label missing for new fields", ->
      proc_missing_label = (errors, column_name) -> errors.missing_label = {columns:[1]}
      check_missing_element_assertion('label', proc_missing_label)

    it "should generate redeable errors one code missing for new fields", ->
      proc_missing_code = (errors, column_name) -> errors.missing_code = {colunms:[1]}
      check_missing_element_assertion('code', proc_missing_code)

    it 'should generate redeable errors for missing name', ->
      errors = {missing_name: {use_as: 'name'}}
      val_errors = new ValidationErrors(errors)
      redeable_errors = val_errors.processErrors()
      expect(redeable_errors.length).toBe(1)
      error = redeable_errors[0]
      expect(error.error_kind).toEqual("missing_name")
      expect(error.description).toEqual("Please select a column to be used as 'Name'")
      expect(error.more_info).toEqual("You need to select a column to be used as 'Name' of the sites in order to continue with the upload.")

   it 'should generate redeable errors for reserved code', ->
      errors = {reserved_code: {name: [0]}}
      val_errors = new ValidationErrors(errors)
      redeable_errors = val_errors.processErrors()
      expect(redeable_errors.length).toBe(1)
      error = redeable_errors[0]
      expect(error.error_kind).toEqual("reserved_code")
      expect(error.description).toEqual("Reserved code 'name'. ResourceMap uses the code 'resmap-id' to identify sites, thus it can't be used as a custom field code.")
      expect(error.more_info).toEqual("Column 1 has code 'name'. To fix this issue, change its code.")

    it "should generate redeable errors data errors", ->
      errors = {data_errors:[]}
      errors.data_errors = [{description: "Some options in column 5 don't exist.", column: 4, rows: [1,2], example: "", type: "options"}, {description: "Some of the values in column 2 are not valid for the type numeric.", column: 1, rows: [1], type: 'numeric values', example: "Values must be integers."}]
      val_errors = new ValidationErrors(errors)
      redeable_errors = val_errors.processErrors()
      expect(redeable_errors.length).toBe(2)
      first_error = redeable_errors[0]
      expect(first_error.error_kind).toBe("data_errors")
      expect(first_error.description).toBe("There are 2 errors in column 5.")
      expect(first_error.columns).toEqual([4])
      expect(first_error.more_info).toEqual("Some options in column 5 don't exist. To fix this, either change the column's type or edit your CSV so that all rows hold valid options. The invalid options are in the following rows: 2 and 3.")
      second_error = redeable_errors[1]
      expect(second_error.error_kind).toEqual("data_errors")
      expect(second_error.description).toEqual("There are 1 errors in column 2.")
      expect(second_error.columns).toEqual([1])
      expect(second_error.more_info).toEqual("Some of the values in column 2 are not valid for the type numeric. To fix this, either change the column's type or edit your CSV so that all rows hold valid numeric values. Values must be integers. The invalid numeric values are in the following rows: 2.")

    it 'should generate messages in singular in existing_code when only one column has issues', ->
      errors = {duplicated_code:[], duplicated_label:[], existing_label:[], existing_code:[], duplicated_usage: [], data_errors: []}
      errors.existing_code = {text_column: [0]}
      val_errors = new ValidationErrors(errors)
      redeable_errors = val_errors.processErrors()
      expect(redeable_errors.length).toBe(1)
      first_error = redeable_errors[0]
      expect(first_error.columns).toEqual([0])
      expect(first_error.more_info).toEqual("Column 1 has code text_column. To fix this issue, change its code.")

    it 'should generate messages in singular in existing_label when only one column has issues', ->
      errors = {duplicated_code:[], duplicated_label:[], existing_label:[], existing_code:[], duplicated_usage: [], data_errors: []}
      errors.existing_label = {text_column: [0]}
      val_errors = new ValidationErrors(errors)
      redeable_errors = val_errors.processErrors()
      expect(redeable_errors.length).toBe(1)
      first_error = redeable_errors[0]
      expect(first_error.columns).toEqual([0])
      expect(first_error.more_info).toEqual("Column 1 has name text_column. To fix this issue, change its name.")

    it 'should filter errors for a column', ->
      errors = {duplicated_code:[], duplicated_label:[], existing_label:[], existing_code:[], duplicated_usage: [], data_errors: []}
      errors.existing_code = {text_column: [0,1]}
      errors.duplicated_label = {other_column: [1, 2]}
      errors.data_errors = [{description: "Some options in column 5 don't exist.", column: 0, rows: [1,2], example: "", type: "options"}, {description: "Some of the values in column 2 are not valid for the type numeric.", column: 1, rows: [1], type: 'numeric values', example: "Values must be integers."}]
      errors.duplicated_code = {text_column: [0, 1]}
      val_errors = new ValidationErrors(errors)
      errors_for_column_0 = val_errors.errorsForColumn(0)
      expect(errors_for_column_0.length).toBe(3)
      errors_for_column_2 = val_errors.errorsForColumn(2)
      expect(errors_for_column_2.length).toBe(1)
      errors_for_column_3 = val_errors.errorsForColumn(3)
      expect(errors_for_column_3.length).toBe(0)








