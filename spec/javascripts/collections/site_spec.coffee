describe 'Collection', ->
  beforeEach ->
    window.runOnCallbacks 'collections'

  describe 'Site', ->

    beforeEach ->
      @data_site = {
        alert:false,
        created_at:"2013-12-20T20:36:42Z",
        icon: "horseriding",
        id_with_prefix: "AG3",
        id:4,
        name: "luhn_site",
        lat:17,
        lat_analyzed: "17",
        lng:17,
        lng_analyzed: "17",
        updated_at: "2014-01-09T13:42:57Z"
        properties: {
          42:"This Luhn"
        },
        type: "site",
        uuid: "a8b87477-71b0-4e2f-8605-89831f49faca",
        version: 82
      }

      @data_collection = {
        id: 1,
        name: "luhn_collection",
        updated_at: "2014-01-09T13:42:57Z",
      }

      @collection = new Collection @data_collection
      spyOn(@collection, 'fetchLogoUrl')
      window.model = new MainViewModel [@collection]

      @luhnFieldData = { id: 50, code: 'luhn_id', name: 'Luhn_id', kind: 'identifier', config: {format: "Luhn" } }
      @textFieldData = { id: 28, code: 'text_field', name: 'Text field', kind: 'text', writeable: true }
      @otherFieldData = { id: 42, code: 'luhn_name', name: 'Luhn name', kind: 'text', writeable: true }

      @luhnField = new Field @luhnFieldData, (esCode) => 'next_value'
      @textField = new Field @textFieldData
      @otherField = new Field @otherFieldData

    describe 'Luhn fields', ->

      beforeEach ->
        @layerData = {fields: [@luhnFieldData, @otherFieldData], name:'luhn_layer'}
        @layer = new Layer @layerData

        @data_site.properties[50] = 20

        @site = new Site @collection, @data_site

        @collection.layers.push(@layer)
        @collection.fields.push(@luhnField)
        @collection.fields.push(@otherField)
        window.model.currentCollection(@collection)

        spyOn(@site, 'createMarker')
        spyOn(@site, 'startEditLocationInMap')

      it 'should edit luhn values in editing mode', ->
        @site.startEditMode()
        expect(@site.collection.fields()[0].value()).toEqual('next_value')

      it 'should delete values when blanking the text fields', ->
        @site.startEditMode()

        expect(@site.properties()[42]).toEqual('This Luhn')
        expect(@site.properties()[50]).toEqual(20)

        @luhnField.value("")
        @otherField.value("Other Luhn")

        @site.copyPropertiesFromCollection(@collection)

        expect(@site.properties()[42]).toBeDefined()
        expect(@site.properties()[50]).toBeDefined()

        expect(@site.properties()[42]).toEqual('Other Luhn')
        expect(@site.properties()[50]).toEqual('')

    describe 'Without identifier fields', ->

      beforeEach ->
        @layerData = {fields: [], name:'luhn_layer'}
        @layer = new Layer @layerData

        @data_site.properties[28] = "Some text"

        @site = new Site @collection, @data_site

        debugger
        @layer.fields.push(@textField)
        @layer.fields.push(@otherField)
        @collection.layers.push(@layer)
        @collection.fields.push(@textField)
        @collection.fields.push(@otherField)
        window.model.currentCollection(@collection)

        spyOn(@site, 'createMarker')
        spyOn(@site, 'startEditLocationInMap')

      it 'should give an empty diff when not in edit mode', ->
        expect(@site.diff()).toBeDefined()
        expect(@site.diff()).toEqual({})

      it 'should give an empty diff when there are no changes', ->
        @site.startEditMode()
        expect(@site.diff()).toBeDefined()
        expect(@site.diff()).toEqual({})

      it 'should show the name changed in the diff', ->
        @site.startEditMode()
        expect(@site.diff()).toBeDefined()
        expect(@site.diff()).toEqual({})
        @site.name("New name")
        expect(@site.diff().name).toBeDefined()
        expect(@site.diff().lat).toBeUndefined()
        expect(@site.diff().lng).toBeUndefined()
        expect(@site.diff().name).toEqual("New name")

      it 'should show the latitude changed in the diff', ->
        @site.startEditMode()
        expect(@site.diff()).toBeDefined()
        expect(@site.diff()).toEqual({})
        @site.lat(42.0)
        expect(@site.diff().lat).toBeDefined()
        expect(@site.diff().lng).toBeUndefined()
        expect(@site.diff().name).toBeUndefined()
        expect(@site.diff().lat).toEqual(42.0)

      it 'should show the longitude changed in the diff', ->
        @site.startEditMode()
        expect(@site.diff()).toBeDefined()
        expect(@site.diff()).toEqual({})
        @site.lng(42.0)
        expect(@site.diff().lat).toBeUndefined()
        expect(@site.diff().lng).toBeDefined()
        expect(@site.diff().name).toBeUndefined()
        expect(@site.diff().lng).toEqual(42.0)

      it "should show a property changed in the diff", ->

        spyOn(@collection, 'fetchFields').andCallFake((callback) =>
          callback()
        )

        @site.copyPropertiesToCollection(@site.collection)
        expect(@collection.fetchFields).toHaveBeenCalledWith(jasmine.any(Function))
        @site.startEditMode()
        expect(@site.diff()).toBeDefined()
        expect(@site.diff()).toEqual({})

        @otherField.value("New value")
        @site.copyPropertiesFromCollection(@collection)

        expect(@site.toJSON()).toBeDefined()
        expect(@site.toJSON().name).toBeDefined()
        expect(@site.toJSON().name).toEqual("luhn_site")
        expect(@site.toJSON().lat).toBeDefined()
        expect(@site.toJSON().lat).toEqual(17)
        expect(@site.toJSON().lng).toBeDefined()
        expect(@site.toJSON().lng).toEqual(17)
        expect(@site.toJSON().properties).toBeDefined()
        expect(@site.toJSON().properties[42]).toBeDefined()
        expect(@site.toJSON().properties[42]).toEqual("New value")
        expect(@site.toJSON().properties[28]).toBeDefined()
        expect(@site.toJSON().properties[28]).toEqual("Some text")

        expect(@site.diff()).toBeDefined()
        expect(@site.diff().name).toBeUndefined()
        expect(@site.diff().lat).toBeUndefined()
        expect(@site.diff().lng).toBeUndefined()
        expect(@site.diff().properties).toBeDefined()
        expect(@site.diff().properties[42]).toBeDefined()
        expect(@site.diff().properties[42]).toEqual("New value")
        expect(@site.diff().properties[28]).toBeUndefined()

      it "should give similar toJSON() and diff() outputs when all site's properties have changed - except for the id", ->
        spyOn(@collection, 'fetchFields').andCallFake((callback) =>
          callback()
        )

        @site.copyPropertiesToCollection(@site.collection)
        expect(@collection.fetchFields).toHaveBeenCalledWith(jasmine.any(Function))
        @site.startEditMode()
        expect(@site.diff()).toBeDefined()
        expect(@site.diff()).toEqual({})

        @site.name("New name")
        @site.lat(25)
        @site.lng(30)
        @textField.value("Other new text")
        @otherField.value("New value")
        @site.copyPropertiesFromCollection(@collection)

        site_to_json = @site.toJSON()
        expect(site_to_json).toBeDefined()
        expect(site_to_json.id).toBeDefined()
        delete site_to_json.id

        expect(@site.diff()).toBeDefined()
        expect(@site.diff()).toEqual(site_to_json)
