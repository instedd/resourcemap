describe 'Collection', ->
  beforeEach ->
    window.runOnCallbacks 'collections'
    window.model = new MainViewModel []

  describe 'RefineViewModel', ->
    beforeEach ->
      @model = window.model
      @collection = new Collection id: 1, name: 'Clinic'
      @collection.allSites([new Site @collection, id: 1, name: 'Site1', updated_at: "2012-07-11T13:46:22-05:00" ])
      @bed_field = new Field id: 1, code: 'bed', name: 'Bed', kind: 'numeric'
      @owner_field = new Field id: 2, code: 'owner', name: 'Owner', kind: 'user'
      @email_field = new Field id: 3, code: 'email', name: 'Email', kind: 'email'
      @phone_field = new Field id: 4, code: 'phone', name: 'Phone', kind: 'phone'
      @date_field = new Field id: 5, code: 'open', name: 'Open', kind: 'date'
      @date_field_2 = new Field id: 6, code: 'close', name: 'Close', kind: 'date'
      @hierarchy = new Field { id: 7, code: 'admu', name: 'Admin unit', kind: 'hierarchy'
      config: { hierarchy: [
        { id: '1', name: 'Buenos Aires'
        sub: [
          { id: '2', name: 'Tres de Febrero' }
          { id: '3', name: 'La Matanza' }
        ]}
        { id: '4', name: 'Santa Fe' }
      ]
      }}
      @numeric_field = new Field id: 8, code: 'number', name: 'Number', kind: 'numeric'
      @site_field = new Field id: 9, code: 'site', name: 'Site', kind: 'site'


    describe 'filter by property', ->
      beforeEach ->
        @collection.fields [@bed_field, @owner_field, @email_field, @phone_field, @date_field, @date_field_2, @hierarchy, @numeric_field, @site_field]
        @model.currentCollection @collection
        spyOn @model, 'performSearchOrHierarchy'

      describe 'of hierarchy kind', ->
        it 'should not have a selected value', ->
          expect(@model.notValueSelected()).toBeTruthy()
          @model.expandedRefineProperty @phone_field.esCode
          expect(@model.notValueSelected()).toBeTruthy()
          @model.expandedRefineProperty @hierarchy.esCode
          @hierarchy.fieldHierarchyItems()[0].fieldHierarchyItems[0].select()
          @model.expandedRefineProperty @phone_field.esCode
          expect(@model.notValueSelected()).toBeTruthy()
          @model.expandedRefineProperty null
          expect(@model.notValueSelected()).toBeTruthy()

        it 'should have a selected value', ->
          @model.expandedRefineProperty @hierarchy.esCode
          @model.expandedRefinePropertyHierarchy(@hierarchy.fieldHierarchyItems()[0].fieldHierarchyItems[0])
          expect(@model.notValueSelected()).toBeFalsy()

        it 'should not add filter if no item is selected', ->
          @model.expandedRefineProperty @hierarchy.esCode
          @model.filterByProperty()
          expect(@model.filters().length).toEqual 0

        it 'should add hierarchy filter', ->
          @model.expandedRefineProperty @hierarchy.esCode
          @model.expandedRefinePropertyHierarchy(@hierarchy.fieldHierarchyItems()[0].fieldHierarchyItems[0])
          @model.filterByProperty()
          expect(@model.filters().length).toEqual 1
          expect(@model.filters()[0].description()).toEqual "with #{@hierarchy.name} under \"Tres de Febrero\""
          expect(@model.filters()[0].value).toEqual '2'

        it 'should filter selected item and its descendants', ->
          @model.expandedRefineProperty @hierarchy.esCode
          @model.expandedRefinePropertyHierarchy(@hierarchy.fieldHierarchyItems()[0])
          @model.filterByProperty()
          expect(@model.filters().length).toEqual 1
          expect(@model.filters()[0].description()).toEqual "with #{@hierarchy.name} under \"Buenos Aires\""
          expect(@model.filters()[0].value).toEqual "1"

        it 'should update current filter value if filtering by existent filter', ->
          @model.expandedRefineProperty @hierarchy.esCode
          @model.expandedRefinePropertyHierarchy(@hierarchy.fieldHierarchyItems()[0])
          @model.filterByProperty()

          expect(@model.filters()[0].description()).toEqual "with #{@hierarchy.name} under \"Buenos Aires\""
          expect(@model.filters()[0].value).toEqual "1"
          expect(@model.filters().length).toEqual 1

          @model.expandedRefineProperty @hierarchy.esCode
          @model.expandedRefinePropertyHierarchy(@hierarchy.fieldHierarchyItems()[0].fieldHierarchyItems[0])
          @model.filterByProperty()

          expect(@model.filters()[0].description()).toEqual "with #{@hierarchy.name} under \"Tres de Febrero\""
          expect(@model.filters()[0].value).toEqual "2"
          expect(@model.filters().length).toEqual 1

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

      describe 'numeric kind', ->
        it 'considers as equal two filters on the same field with the same operator', ->
          @model.expandedRefineProperty @numeric_field.esCode
          @model.expandedRefinePropertyOperator('<')
          @model.expandedRefinePropertyValue(15)
          @model.filterByProperty()
          expect(@model.filters().length).toEqual 1

          @model.expandedRefineProperty @numeric_field.esCode
          @model.expandedRefinePropertyOperator('<')
          @model.expandedRefinePropertyValue(1)
          @model.filterByProperty()
          expect(@model.filters().length).toEqual 1

        it 'considers as different two filters on the same field with different operator', ->
          @model.expandedRefineProperty @numeric_field.esCode
          @model.expandedRefinePropertyOperator('<')
          @model.expandedRefinePropertyValue(15)
          @model.filterByProperty()
          expect(@model.filters().length).toEqual 1

          @model.expandedRefineProperty @numeric_field.esCode
          @model.expandedRefinePropertyOperator('>')
          @model.expandedRefinePropertyValue(1)
          @model.filterByProperty()
          expect(@model.filters().length).toEqual 2

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

        it 'should add filter with same paramters to other property', ->
            model.expandedRefineProperty @date_field.esCode
            @model.filterByProperty()
            expect(@model.filters().length).toEqual 1
            model.expandedRefineProperty @date_field_2.esCode
            @model.expandedRefinePropertyDateFrom '12/26/1988'
            @model.expandedRefinePropertyDateTo '12/28/1988'
            @model.filterByProperty()
            expect(@model.filters().length).toEqual 2

        it 'should not add filter if any date is absent', ->
            model.expandedRefineProperty @date_field.esCode
            @model.filterByProperty()
            expect(@model.filters().length).toEqual 1
            model.expandedRefineProperty @date_field_2.esCode
            @model.expandedRefinePropertyDateFrom '12/26/1988'
            @model.filterByProperty()
            expect(@model.filters().length).toEqual 1

        it 'should determine if dates are in correct format', ->
            @model.expandedRefinePropertyDateFrom 'sarasa'
            @model.expandedRefinePropertyDateTo '12/28/1988'
            expect(@model.anyDateParameterWithInvalidFormat()).toEqual true

        it 'should not add filter if any date is not in correct format', ->
            @model.expandedRefinePropertyDateFrom '12/2'
            @model.expandedRefinePropertyDateTo '12/28/1988'
            model.expandedRefineProperty @date_field.esCode
            @model.filterByProperty()
            expect(@model.filters().length).toEqual 0

      describe 'site kind', ->
        beforeEach ->
          @model.expandedRefinePropertyValue 'site1'

        it 'should add text filter', ->
          @model.expandedRefineProperty @site_field.esCode
          @model.filterByProperty()
          expect(@model.filters().length).toEqual 1
          expect(@model.filters()[0].description()).toEqual "where #{@site_field.name} is \"site1\""

        it 'should not add filter if site is absent', ->
          model.expandedRefineProperty @site_field.esCode
          @model.expandedRefinePropertyValue(null)
          @model.filterByProperty()
          expect(@model.filters().length).toEqual 0

