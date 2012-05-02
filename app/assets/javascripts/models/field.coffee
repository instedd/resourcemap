$ ->
  module 'rm'
  rm.Field = class Field
    constructor: (field) ->
      @code = ko.observable field?.code
      @name = ko.observable field?.name
      @kind = ko.observable field?.kind
      @writeable = ko.observable field?.writeable
      @options = if field.config?.options?
                   ko.observableArray($.map(field.config.options, (x) => new Option(x)))
                 else
                   ko.observableArray()
      @optionsCodes = ko.computed => $.map(@options(), (x) => x.code())
      @value = ko.observable()
      @hasValue = ko.computed => @value() && (if @kind() == 'select_many' then @value().length > 0 else @value())
      #@valueUI = ko.computed => @valueUIFor(@value())
      @remainingOptions = ko.computed =>
        if @value()
          @options().filter((x) => @value().indexOf(x.code()) == -1)
        else
          @options()

      @editing = ko.observable false

      
