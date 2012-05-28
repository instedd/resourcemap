describe 'MainViewModel', ->
  beforeEach ->
    window.runOnCallbacks 'thresholds'

    @collectionId = 1
    @model = new MainViewModel @collectionId, [{id: 1, code: 'beds'}]

  it 'should find field', ->
    expect(@model.findField('1')).toBe @model.fields()[0]

  describe 'cancel threshold', ->
    beforeEach ->
      @threshold = new Threshold conditions: [], color: 'red'
      @model.thresholds.push @threshold
      @model.currentThreshold @threshold
      @model.editThreshold(@threshold)

    it 'should remove if new', ->
      @model.cancelThreshold()
      expect(@model.thresholds().length).toBe 0
      expect(@model.currentThreshold()).toBeNull()

    it 'should not remove if saved', ->
      @threshold.id(1)
      @model.cancelThreshold()
      expect(@model.thresholds().length).toBe 1
      expect(@model.currentThreshold()).toBeNull()

  describe 'save threshold', ->
    beforeEach ->
      @threshold = new Threshold conditions: [], color: 'red', ord: 1
      @model.thresholds.push @threshold
      @model.currentThreshold @threshold
      spyOn($, 'post')

    it "should post the threshold's json", ->
      @model.saveThreshold()
      expect($.post).toHaveBeenCalledWith("/collections/#{@collectionId}/thresholds.json", {threshold: {conditions: [], color: 'red', ord: 1}}, @model.saveThresholdCallback)

    it "should put the threshold's json if it has an id", ->
      @threshold.id(1)
      @model.saveThreshold()
      expect($.post).toHaveBeenCalledWith("/collections/#{@collectionId}/thresholds/1.json", {_method: 'put', threshold: {id: 1, conditions: [], color: 'red', ord: 1}}, @model.saveThresholdCallback)

    it 'should be saving', ->
      @model.saveThreshold()
      expect(@model.saving()).toBeTruthy()

    it 'should null the current threshold in the callback', ->
      @model.saveThresholdCallback()
      expect(@model.currentThreshold()).toBeNull()

    it 'should not be saving in the callback', ->
      @model.saving(true)
      @model.saveThresholdCallback()
      expect(@model.saving()).toBeFalsy()

    it 'should assign the id of the new threshold', ->
      @model.saveThresholdCallback(id: 1)
      expect(@threshold.id()).toEqual 1

  describe 'add threshold', ->
    beforeEach ->
      @model.addThreshold()

    it 'should add threshold to thresholds', ->
      expect(@model.thresholds().length).toEqual 1

    it 'should set the first threshold ord to 1', ->
      expect(@model.thresholds()[0].ord()).toEqual 1

    it 'should set ord to max ord plus one', ->
      @model.thresholds()[0].ord(2)
      @model.addThreshold()
      expect(@model.thresholds()[1].ord()).toEqual 3

    it 'should add one condition', ->
      expect(@model.thresholds()[0].conditions().length).toEqual 1

  describe 'edit threshold', ->
    beforeEach ->
      @threshold = new Threshold id: 1, conditions: [], color: 'red'
      @model.thresholds.push @threshold
      @model.editThreshold @threshold

    it 'should restore the color when canceling', ->
      @threshold.color('blue')
      @model.cancelThreshold()
      expect(@model.thresholds()[0].color()).toBe 'red'

    it 'should restore the conditions when canceling', ->
      @threshold.conditions [new Condition]
      @model.cancelThreshold()
      expect(@model.thresholds()[0].conditions().length).toEqual 0

  describe 'delete threshold', ->
    beforeEach ->
      @threshold = new Threshold id: 1, conditions: [], color: 'red'
      @model.thresholds.push @threshold

    it 'should show confirm dialog', ->
      spyOn window, 'confirm'
      @model.deleteThreshold @threshold
      expect(window.confirm).toHaveBeenCalledWith 'Are you sure to delete threshold?'

    it "should delete the threshold's json", ->
      spyOn(window, 'confirm').andReturn true
      spyOn($, 'post').andReturn true
      @model.deleteThreshold @threshold
      @expect($.post).toHaveBeenCalledWith "/collections/#{@collectionId}/thresholds/#{@threshold.id()}.json", { _method: 'delete' }, @model.deleteThresholdCallback
