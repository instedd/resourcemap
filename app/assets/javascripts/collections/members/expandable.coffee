class @Expandable extends Module
  constructor: ->
    @expanded = ko.observable true

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

  toggleAllRead: =>
    switch @allRead()
      when 'tristate-partial', 'tristate-unchecked'
        link.canRead(true) for link in @membershipLayerLinks()
      else
        link.canRead(false) for link in @membershipLayerLinks()

  toggleAllWrite: =>
    switch @allWrite()
      when 'tristate-partial', 'tristate-unchecked'
        link.canWrite(true) for link in @membershipLayerLinks()
      else
        link.canWrite(false) for link in @membershipLayerLinks()
