describe 'ImportWizard', ->
  beforeEach ->
    window.runOnCallbacks 'importWizard'
    window.model = new MainViewModel
    @layers = [{id: 1, name: "layer 1", fields: [{id: 1, name: "field 1", kind: 'text', code: 'field1'}, {id: 2, name: "field 2", kind: 'text', code: 'field2'}] },
      {id: 2, name: "layer 2", fields: [{id: 3, name: "field 3", kind: 'text', code: 'field3'}, {id: 4, name: "field 4", kind: 'text', code: 'field4'}] }
      ]
    @columns =[{header: "field 1", use_as: "name"}]
    @model = window.model

  describe 'MainViewModel', ->
    it 'should load usages for no layer', ->
      @model.initialize(1, [], @columns)

      expect(window.arrayAny(@model.usages, (x) -> (x.name == 'Existing field' && x.code == 'existing_field'))).toBe(false)
      expect(window.arrayAny(@model.selectableUsagesForAdmins, (x) -> (x.name == 'Existing field' && x.code == 'existing_field'))).toBe(false)
      expect(window.arrayAny(@model.selectableUsagesForNonAdmins, (x) -> (x.name == 'Existing field' && x.code == 'existing_field'))).toBe(false)

    it 'should load existing field in usages if layer exists', ->
      @model.initialize(1, @layers, @columns)
      expect(window.arrayAny(@model.usages, (x) -> (x.name == 'Existing field' && x.code == 'existing_field'))).toBe(true)
      expect(window.arrayAny(@model.usages, (x) -> (x.name == 'resmap-id' && x.code == 'id'))).toBe(true)
      expect(window.arrayAny(@model.selectableUsagesForAdmins, (x) -> (x.name == 'Existing field' && x.code == 'existing_field'))).toBe(true)
      expect(window.arrayAny(@model.selectableUsagesForNonAdmins, (x) -> (x.name == 'Existing field' && x.code == 'existing_field'))).toBe(true)

    it 'should not include id field in selectable usages', ->
      @model.initialize(1, @layers, @columns)
      expect(window.arrayAny(@model.selectableUsagesForAdmins, (x) -> (x.name == 'resmap-id' && x.code == 'id'))).toBe(false)
      expect(window.arrayAny(@model.selectableUsagesForNonAdmins, (x) -> (x.name == 'resmap-id' && x.code == 'id'))).toBe(false)

    it 'should not allow non admins to create a new field', ->
      @model.initialize(1, @layers, @columns)
      expect(window.arrayAny(@model.selectableUsagesForNonAdmins, (x) -> (x.name == 'New field' && x.code == 'new_field'))).toBe(false)

    it 'imported sites should not have id when the import wizard is created', ->
      @model.initialize(1, [], @columns)
      expect(@model.hasId()).toBe(false)

    it 'imported sites should have id if site has a column  with usage id', ->
      @model.initialize(1, @layers, @columns)
      expect(@model.hasId()).toBe(false)
      columns = [{header: "resmap-id", use_as: "id"}]
      @model.initialize(1, @layers, columns)
      expect(@model.hasId()).toBe(true)

    it 'should find field in layers by field_id', ->
      @model.initialize(1, @layers, @columns)
      expect(@model.findField(1).code).toBe('field1')
      expect(@model.findField('1').code).toBe('field1')
      expect(@model.findField('inexisting')).toBeFalsy()

    it 'columns should have index', ->
      @model.initialize(1, @layers, @columns)
      expect(@model.columns()[0].index).toBe(0)

    it 'should change errors in columns if validationErrors changes', ->
      @model.initialize(1, @layers, @columns)
      expect(@model.columns()[0].errors().length).toBe(0)
      errors = {duplicated_code:[], duplicated_label:[], existing_label:[], existing_code:[], usage_missing:[], duplicated_usage: [], data_errors: []}
      errors.existing_code = {text_column: [0]}
      @model.validationErrors(new ValidationErrors(errors))
      expect(@model.columns()[0].errors().length).toBe(1)

  describe "ImportWizard Sites specs", ->
    beforeEach ->
      columns = [{header: "name", use_as: "name"}, {header: 'lat', use_as: 'lat'}, {layer_id: 1, field_id: 209, header: "many", use_as: "existing_field"}]
      layers = [{id: 1, name: "layer 1", fields: [{id: 209, name: "Funding", kind: 'select_many', code: 'field1'}] }]
      @model.initialize(1, layers, columns)
      preview = {}
      preview.errors = []
      preview.sites = [[{value: 'Buenos Aires Hospital'}, {value: '-34.6036'}, {value: 'public'}],
            [{value: 'New York Hospital'}, {value: '40.7142'}, {value: 'private'}],
            [{value: 'Phnom Penh Hospital'}, {value: '11.5500'}, {value: 'public'}]]
      @model.loadSites(preview)

    it 'should load sites preview for all columns when we are not filtering by error columns', ->
      expect(@model.visibleSites().length).toBe 3
      expect(@model.visibleSites()[0].siteColumns.length).toBe 3
      expect(@model.visibleSites()[1].siteColumns.length).toBe 3
      expect(@model.visibleSites()[2].siteColumns.length).toBe 3
      expect(@model.showingColumns()).toBe 'all'

    it 'should load only sites & columns with error when filtering by error columns', ->
      errors_for_column = [
        columns: Array[2]
        description: "Only one column can be the lat."
        error_kind: "duplicated_usage"
        more_info: "Columns 3 and 4 are marked as lat. To fix this issue, leave only one of them assigned as 'lat' and modify the rest."
      ]
      @model.columns()[0].errors(errors_for_column)
      @model.showColumnsWithErrors()
      expect(@model.visibleSites().length).toBe 3
      expect(@model.visibleSites()[0].siteColumns.length).toBe 1
      expect(@model.visibleSites()[1].siteColumns.length).toBe 1
      expect(@model.visibleSites()[2].siteColumns.length).toBe 1
      expect(@model.visibleColumns().length).toBe 1
      expect(@model.showingColumns()).toBe 'with_errors'

    it 'should load only sites & columns with usage=existing_field', ->
      @model.showExistingColumns()
      expect(@model.visibleSites().length).toBe 3
      expect(@model.visibleSites()[0].siteColumns.length).toBe 1
      expect(@model.visibleSites()[1].siteColumns.length).toBe 1
      expect(@model.visibleSites()[2].siteColumns.length).toBe 1
      expect(@model.visibleColumns().length).toBe 1
      expect(@model.visibleColumns()[0].header()).toBe 'many'
      expect(@model.showingColumns()).toBe 'existing'

    it 'shhould change column usage when corresponding visibleColumn usage changes', ->
      @model.visibleColumns()[1].usage('lng')
      expect(@model.visibleColumns()[1].usage()).toBe 'lng'
      expect(@model.columns()[1].usage()).toBe 'lng'


