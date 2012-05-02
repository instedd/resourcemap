#= require models/field

describe 'Field', ->
  beforeEach ->
    @field = new rm.Field {name: "Ambulance", code: "AB", kind: "numeric"}
  
  it 'should has name', ->
    expect(@field.name()).toEqual "Ambulance"

  it 'should has code', ->
    expect(@field.code()).toEqual "AB"

  it 'should has kind', ->
    expect(@field.kind()).toEqual "numeric"
