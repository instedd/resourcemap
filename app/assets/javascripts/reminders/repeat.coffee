onReminders ->
  class @Repeat 
    constructor: (data) ->
      @id = ko.observable data?.id
      @name = ko.observable data?.name
      @order = ko.observable data?.order
