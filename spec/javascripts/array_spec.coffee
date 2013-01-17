describe "Array extensions", ->
  it "should convert array to sentence", ->
    expect(window.toSentence([])).toEqual ""
    expect(window.toSentence([1])).toEqual "1"
    expect(window.toSentence([1,2])).toEqual "1 and 2"
    expect(window.toSentence([1,2,3])).toEqual "1, 2 and 3"
    expect(window.toSentence([1,2,3,4])).toEqual "1, 2, 3 and 4"



