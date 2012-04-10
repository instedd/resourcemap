$ ->
  module 'rm'

  rm.Threshold = class Threshold
    constructor: (data) ->
      @id = ko.observable data?.id
      @priority = ko.observable data?.priority
      @color = ko.observable data?.color
      @condition = ko.observable data?.condition
