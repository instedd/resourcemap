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
          42:"This Luhn",
          50:20
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
      window.model = new MainViewModel [@collection]

      @field = new Field { id: 50, code: 'luhn_id', name: 'Luhn_id', kind: 'identifier', config: {format: "Luhn" } }, (esCode) -> 'next_value'

      @otherField = new Field { id: 42, code: 'luhn_name', name: 'Luhn name', kind: 'text', writeable: true }

      @layer = new Layer({fields: {@field, @otherField}, name:'luhn_layer'})

      @site = new Site @collection, @data_site

      @collection.layers.push(@layer)
      @collection.fields.push(@field)
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

      @field.value("")
      @otherField.value("Other Luhn")

      @site.copyPropertiesFromCollection(@collection)
      
      expect(@site.properties()[42]).toBeDefined()
      expect(@site.properties()[50]).toBeDefined()

      expect(@site.properties()[42]).toEqual('Other Luhn')
      expect(@site.properties()[50]).toEqual('')

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
