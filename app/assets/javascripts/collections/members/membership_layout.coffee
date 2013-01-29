class @MembershipLayout
  @constructor: (root, data) ->
    @customPermissionsHeight = ko.computed =>
      pixelsWithoutPermissions = 46
      pixelsPerPermission = 32
      permissionsListMargin = 3
      hrPixels = 0

      customPermissions = @sitesWithCustomPermissions().length

      permissionsListMargin = 8 if customPermissions > 0

      hrPixels = (customPermissions - 1) if customPermissions > 0

      customPermissions * pixelsPerPermission + permissionsListMargin + hrPixels + pixelsWithoutPermissions

    @customPermissionsHeightPx = ko.computed => "#{@customPermissionsHeight()}px"

    @detailHeight = ko.computed => (root.layers().length * 38) + 90 + @customPermissionsHeight()
    @detailHeightPx = ko.computed => "#{@detailHeight()}px"

    @lastCellContentHeight = ko.computed => @detailHeight() + 32
    @lastCellContentHeightPx = ko.computed => "#{@lastCellContentHeight()}px"
