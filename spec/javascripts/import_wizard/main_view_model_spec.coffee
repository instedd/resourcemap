describe 'ImportWizard', ->
  beforeEach ->
    window.runOnCallbacks 'importWizard'
    window.model = new MainViewModel
    @layers = [{id: 1, name: "layer 1", fields: [{id: 1, name: "field 1", kind: 'text', code: 'field1'}, {id: 2, name: "field 2", kind: 'text', code: 'field2'}] },
      {id: 2, name: "layer 2", fields: [{id: 3, name: "field 3", kind: 'text', code: 'field3'}, {id: 4, name: "field 4", kind: 'text', code: 'field4'}] }
      ]
    @columns =[{name: "field 1", usage: "name"}]
    @model = window.model

    window.Column::applyColumnBubble = () ->
      true

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
