moduleKeywords = ['extended', 'included']

# See http://arcturo.github.com/library/coffeescript/03_classes.html (Extending classes)
class window.Module
  @include: (obj) ->
    for key, value of obj when key not in moduleKeywords
      # Assign properties to the prototype
      @::[key] = value
    this
