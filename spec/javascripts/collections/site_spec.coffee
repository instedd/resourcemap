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
        long:17,
        long_analyzed: "17",
        updated_at: "2014-01-09T13:42:57Z"
        properties: {
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

      @field = new Field { id: 1, code: 'luhn_id', name: 'Luhn_id', kind: 'identifier', config: {format: "Luhn" } }, (esCode) -> 'next_value'

      @layer = new Layer({fields: {@field}, name:'luhn_layer'})

      @site = new Site @collection, @data_site

      @collection.layers.push(@layer)
      @collection.fields.push(@field)
      window.model.currentCollection(@collection)

      spyOn(@site, 'createMarker')
      spyOn(@site, 'startEditLocationInMap')

    it 'should edit luhn values in editing mode', ->
      @site.startEditMode()
      expect(@site.collection.fields()[0].value()).toEqual('next_value')



