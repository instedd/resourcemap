describe 'Field', ->
  beforeEach ->
    @field = new Field { id: 1, code: 'beds', name: 'Available beds', kind: 'numeric' }

  it 'shoule not be editing', ->
    expect(@field.editing()).toBeFalsy()
