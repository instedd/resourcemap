$(-> if $('#collections-main').length > 0

  class window.Option
    constructor: (data) ->
      @code = ko.observable(data?.code)
      @label = ko.observable(data?.label)
      @selected = ko.observable(false)

)
