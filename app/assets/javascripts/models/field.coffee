#= require models/comparison_options

$ ->
  module 'rm'

  rm.Field = class Field

    constructor: (data) ->
      @name = ko.observable data?.name
      @code = ko.observable data?.code
      @kind = ko.observable data?.kind
      @config = ko.observable data?.config

      @comparisonOptions = ko.computed => rm.Utils.hashToArray rm.ComparisonOptions[@kind()]
