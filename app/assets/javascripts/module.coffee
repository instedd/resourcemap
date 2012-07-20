moduleKeywords = ['extended', 'included']

# See http://arcturo.github.com/library/coffeescript/03_classes.html (Extending classes)
class window.Module
  @include: (obj) ->
    for key, value of obj when key not in moduleKeywords
      if key == 'constructor'
        (@::moduleConstructors ||= []).push value
      else
        # Assign properties to the prototype
        @::[key] = value
    this

  callModuleConstructors: (args) ->
    ctor.apply this, args for ctor in @moduleConstructors if @moduleConstructors

  aliasMethodChain: (method, feature) ->
    @[method + "Without" + feature] = @[method]
    @[method] = @[method + "With" + feature]