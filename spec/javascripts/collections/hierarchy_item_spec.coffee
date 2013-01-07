describe 'Collection', ->
  beforeEach ->
    window.runOnCallbacks 'collections'

  describe 'Hierarchy Item', ->
    beforeEach ->
      @collection = new Collection id: 1
      window.model = new MainViewModel [@collection]
      @field = new Field { id: 1, code: 'admu', name: 'Admin Unit', kind: 'select_one', writeable: true }
      @col_hierarchy = new CollectionHierarchy(@collection, @field)
      window.model.initialize [@collection]

    it 'should have hierarchyIds', ->
      hierarchyItem = new HierarchyItem(@col_hierarchy, @field, {id: 1, name: "name1", sub: [{id: 2, name: "name2", sub: [{id:3, name: "name3", sub: [] }]}, {id: 4, name: "name4", sub: []}] }, 0)
      expect(hierarchyItem.hierarchyIds()).toEqual([1, 2, 3, 4])
