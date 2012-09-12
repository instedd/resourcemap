describe 'Collection', ->
  beforeEach ->
    window.runOnCallbacks 'collections'
    window.model = new MainViewModel
    window.model.initialize []

  describe 'RefineViewModel', ->
    beforeEach ->
      @model = window.model
      @collection = new Collection id: 1, name: 'Clinic'
      @bed_field = new Field id: 1, code: 'bed', name: 'Bed', kind: 'numeric'
      @owner_field = new Field id: 2, code: 'owner', name: 'Owner', kind: 'user'
      @email_field = new Field id: 3, code: 'email', name: 'Email', kind: 'email'
      @phone_field = new Field id: 4, code: 'phone', name: 'Phone', kind: 'phone'
      @date_field = new Field id: 5, code: 'open', name: 'Open', kind: 'date'


    describe 'filter by property', ->
      beforeEach ->
        @collection.fields [@bed_field, @owner_field, @email_field, @phone_field, @date_field]
        @model.currentCollection @collection
        spyOn @model, 'performSearchOrHierarchy'

      describe 'plugin kind', ->
        beforeEach -> @model.expandedRefinePropertyValue 'foo'

        it 'of user should add text filter', ->
          @model.expandedRefineProperty @owner_field.esCode
          @model.filterByProperty()
          expect(@model.filters().length).toEqual 1
          expect(@model.filters()[0].description()).toEqual "where #{@owner_field.name} starts with \"foo\""

        it 'of email should add text filter', ->
          @model.expandedRefineProperty @email_field.esCode
          @model.filterByProperty()
          expect(@model.filters().length).toEqual 1
          expect(@model.filters()[0].description()).toEqual "where #{@email_field.name} starts with \"foo\""

        it 'of phone should add text filter', ->
          @model.expandedRefineProperty @phone_field.esCode
          @model.filterByProperty()
          expect(@model.filters().length).toEqual 1
          expect(@model.filters()[0].description()).toEqual "where #{@phone_field.name} starts with \"foo\""

      describe 'date kind', ->
        beforeEach ->
          @model.expandedRefinePropertyDateFrom '12/26/1988'
          @model.expandedRefinePropertyDateTo '12/28/1988'

         it 'of date should add text filter', ->
            @model.expandedRefineProperty @date_field.esCode
            @model.filterByProperty()
            expect(@model.filters().length).toEqual 1
            expect(@model.filters()[0].description()).toEqual "where #{@date_field.name} is between 12/26/1988 and 12/28/1988"

        it 'should not add same filter twice', ->
            model.expandedRefineProperty @date_field.esCode
            @model.filterByProperty()
            expect(@model.filters().length).toEqual 1
            @model.filterByProperty()
            expect(@model.filters().length).toEqual 1




