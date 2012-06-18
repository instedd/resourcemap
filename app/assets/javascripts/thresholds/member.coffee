onThresholds ->
  class @Member
    constructor: (data) ->
      @id = ko.observable data?.id 
      @email = ko.observable data?.email
      @isSelected = ko.observable data?.isSelected ? false

    toJSON: =>
      email: @email()
      isSelected: @isSelected
      
