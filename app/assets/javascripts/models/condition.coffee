#= require models/field

$ ->
  module 'rm'

  rm.Condition = class Condition

    @Types =
      value: 'a value of'
      percent: 'a percent of'

    constructor: (data) ->
      @field = ko.observable data?.field
      @is = ko.observable data?.is
      @type = ko.observable data?.type ? 'value'
      @rawValue = ko.observable data?.value

      @comparison = ko.computed => rm.ComparisonOptions.getText @is()
      @value = ko.computed => if @type() == 'value' then "#{@rawValue()}" else "#{@rawValue()}%"
      @types = rm.Utils.hashToArray Condition.Types
      @error = ko.computed => return "value is missing" unless @rawValue()
      @valid = ko.computed => not @error()?
