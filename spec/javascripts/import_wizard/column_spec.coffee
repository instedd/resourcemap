describe 'Columns', ->
  window.runOnCallbacks 'importWizard'

  beforeEach ->
    @column = new Column({header: 'field 1', use_as: 'name' }, 0)
  
  describe 'Column headers', ->
    it 'should change column header according to the update data', ->
      @column.update({use_as: 'lat'})
      expect(@column.iconClass()).toBe('flocation')
