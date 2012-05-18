#= require models/comparison_options

describe 'Comparison options', ->

  comparisons =
    lt: 'is less than'
    gt: 'is greater than'
    eq: 'is equals to'
    con: 'contains'

  for key, text of comparisons
    it "should has :#{key} comparison", ->
      expect(rm.ComparisonOptions.getText key).toEqual text
