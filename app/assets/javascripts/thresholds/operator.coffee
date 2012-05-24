onThresholds ->
  class @Operator
    @LT = new Operator('lt', 'is less than')
    @GT = new Operator('gt', 'is greater than')
    @EQ = new Operator('eq', 'is equal to')
    @CON = new Operator('con', 'contains')

    constructor: (code, label) ->
      @code = ko.observable code
      @label = ko.observable label

    @findByCode: (code) ->
      @[code?.toUpperCase()]
