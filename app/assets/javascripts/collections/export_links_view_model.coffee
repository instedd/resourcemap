onCollections ->

  class @ExportLinksViewModel
    @exportInRSS: -> window.open @currentCollection().link('rss')
    @exportInJSON: -> window.open @currentCollection().link('json')
    @exportInCSV: -> window.location = @currentCollection().link('csv')
