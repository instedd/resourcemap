class @MembershipLayout
  @constructor: (root, data) ->
    @customPermissionsHeight = ko.computed => (@sitesWithCustomPermissions().length * 35) + 57
    @customPermissionsHeightPx = ko.computed => "#{@customPermissionsHeight()}px"

    @detailHeight = ko.computed => (root.layers().length * 38) + 82 + @customPermissionsHeight()
    @detailHeightPx = ko.computed => "#{@detailHeight()}px"

    @lastCellContentHeight = ko.computed => @detailHeight() + 32
    @lastCellContentHeightPx = ko.computed => "#{@lastCellContentHeight()}px"
