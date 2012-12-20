#= require module
#= require collections/sites_container

onCollections ->

  # Used when grouping by a hierarchy field
  class @HierarchyItem extends Module
    @include SitesContainer

    constructor: (collection, field, data, level = 0) ->
      @constructorSitesContainer()

      @field = field

      collection.hierarchyItemsMap[data.id] = @

      @id = data.id

      @name = data.name ? data.label
      @level = level
      @selected = ko.observable(false)
      @hierarchyItems = if data.sub?
                          $.map data.sub, (x) => new HierarchyItem(collection, @field, x, level + 1)
                        else
                          []

      @hierarchyIds = ko.observable([@id])
      $.map @hierarchyItems, (item) => @loadItemToHierarchyIds(item)

      # Styles
      @labelStyle = @style()['labelStyle']
      @columnStyle = @style()['columnStyle']

      @isSelected = ko.computed => @ == window.model.selectedHierarchy()

    # public
    loadItemToHierarchyIds: (item) =>
      @hierarchyIds().push(item.id)
      $.map item.hierarchyItems, (item) => @loadItemToHierarchyIds(item)

    sitesUrl: =>
      "/collections/#{window.model.currentCollection().id}/search.json?#{$.param @queryParams()}"

    queryParams: =>
      hierarchy_code: @field.esCode
      hierarchy_value: @id

    createSite: (site) => new Site(window.model.currentCollection().collection, site)

    # private
    style: =>
      pixels_per_indent_level = 20
      row_width = 300

      indent = @level * pixels_per_indent_level

      {
        columnStyle: {
          height: '30px',
          cursor: 'pointer'
        }
        labelStyle: {
          width: "#{row_width - 28 - indent}px",
          marginLeft: "#{6 + indent}px",
          paddingLeft: '2px',
          marginTop: '1px'
        }
      }

