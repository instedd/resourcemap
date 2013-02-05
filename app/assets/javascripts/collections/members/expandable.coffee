class @Expandable extends Module
  constructor: ->
    @expanded = ko.observable false

  toggleExpanded: => @expanded(!@expanded())
