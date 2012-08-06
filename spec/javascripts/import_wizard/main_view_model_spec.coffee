describe 'ImportWizard', ->
  beforeEach ->
    window.runOnCallbacks 'importWizard'
    window.model = new MainViewModel
    @layers = [{id: 1, name: "layer 1", fields: [] }]
    @columns =[{name: "field 1", usage: "name", sample: "res name", value: "res name"}]
    @model = window.model

  describe 'MainViewModel', ->
    it 'should load usages for no layer', ->
      @model.initialize(1, [], @columns)
      expect(@model.usages.any( (x) -> (x.name == 'Existing field' && x.code == 'existing_field'))).toBe(false)
      expect(@model.selectableUsages.any( (x) -> (x.name == 'Existing field' && x.code == 'existing_field'))).toBe(false)

    it 'should load existing field in usages if layer exists', ->
      @model.initialize(1, @layers, @columns)
      expect(@model.usages.any( (x) -> (x.name == 'Existing field' && x.code == 'existing_field'))).toBe(true)
      expect(@model.selectableUsages.any( (x) -> (x.name == 'Existing field' && x.code == 'existing_field'))).toBe(true)

    it 'should not include id field in selectable usages', ->
      @model.initialize(1, @layers, @columns)
      expect(@model.selectableUsages.any( (x) -> (x.name == 'ID' && x.code == 'id'))).toBe(false)

    it 'should not include id field in selectable usages', ->
      @model.initialize(1, @layers, @columns)
      expect(@model.selectableUsages.any( (x) -> (x.name == 'ID' && x.code == 'id'))).toBe(false)

    it 'imported sites should not have id when the import wizard is created', ->
      @model.initialize(1, [], @columns)
      expect(@model.hasId()).toBe(false)

    it 'imported sites should have id when site is computed if site has a column id', ->
      @model.initialize(1, @layers, @columns)
      expect(@model.hasId()).toBe(false)
      @columns =[{name: "id", usage: "id", sample: "1", value: "1"}]
      @model.initialize(1, @layers, @columns)
      expect(@model.hasId()).toBe(true)




