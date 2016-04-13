onCollections ->

  class @ExportLinksViewModel
    @exportInRSS: -> window.open @currentCollection().exportUrl('rss')
    @exportInJSON: -> window.open @currentCollection().exportUrl('json')
    @exportInCSV: -> window.location = @currentCollection().exportUrl('csv')
