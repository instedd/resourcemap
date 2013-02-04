class @Expandable extends Module
  constructor: ->
    @expanded = ko.observable false

  toggleExpanded: => @expanded(!@expanded())

  initializeAllReadAllWrite: =>
    @allRead = ko.computed => @allReadOrWrite((x) -> x.canRead())
    @allWrite = ko.computed => @allReadOrWrite((x) -> x.canWrite())

    @allReadUI = ko.computed => @allReadOrWriteUI(=> @allRead())
    @allWriteUI = ko.computed => @allReadOrWriteUI(=> @allWrite())

  allReadOrWrite: (func) =>
    foundFalse = false
    foundTrue = false
    allAdmin = true
    for link in @membershipLayerLinks()
      continue if link.membership.admin()
      allAdmin = false
      foundTrue = true if func(link)
      foundFalse = true unless func(link)
    return 'tristate-checked' if allAdmin
    if foundTrue && foundFalse then "tristate-partial" else if foundTrue then "tristate-checked" else "tristate-unchecked"

  allReadOrWriteUI: (func) =>
    switch func()
      when 'tristate-partial' then '---'
      when 'tristate-checked' then 'Yes'
      when 'tristate-unchecked' then 'No'
