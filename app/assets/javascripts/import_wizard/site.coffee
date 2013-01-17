onImportWizard ->
  class @Site
    constructor: (data) ->
      @siteColumns = $.map(data, (x) -> new SiteColumn(x))
