onLayers ->
  class @Field
    constructor: (layer, data) ->
      @layer = layer
      @id = ko.observable data?.id
      @name = ko.observable data?.name
      @code = ko.observable data?.code
      @kind = ko.observable data?.kind
      @ord = ko.observable data?.ord
      @options = if data.config?.options?
                   ko.observableArray($.map(data.config.options, (x) -> new Option(x)))
                 else
                   ko.observableArray()
      @nextId = data.config?.next_id || @options().length + 1
      @hierarchy = ko.observable data.config?.hierarchy
      @initHierarchyItems() if @hierarchy()
      @hasFocus = ko.observable(false)
      @isOptionsKind = ko.computed => @kind() == 'select_one' || @kind() == 'select_many'
      @uploadingHierarchy = ko.observable(false)
      @errorUploadingHierarchy = ko.observable(false)
      @fieldErrorDescription = ko.computed => if @hasName() then "'#{@name()}'" else "number #{@layer.fields().indexOf(@) + 1}"
      @nameError = ko.computed => if @hasName() then null else "the field #{@fieldErrorDescription()} is missing a Name"
      @codeError = ko.computed => if @hasCode() then null else "the field #{@fieldErrorDescription()} is missing a Code"
      @optionsError = ko.computed =>
        return null unless @isOptionsKind()

        if @options().length > 0
          codes = []
          labels = []
          for option in @options()
            return "duplicated option code '#{option.code()}' for field #{@name()}" if codes.indexOf(option.code()) >= 0
            return "duplicated option label '#{option.label()}' for field #{@name()}" if labels.indexOf(option.label()) >= 0
            codes.push option.code()
            labels.push option.label()
          null
        else
          "the field '#{@name()}' must have at least one option"
      @hierarchyError = ko.computed =>
        return null unless @kind() == 'hierarchy'
        if @hierarchy() && @hierarchy().length > 0 then null else "the field #{@fieldErrorDescription()} is missing the Hierarchy"
      @error = ko.computed => @nameError() || @codeError() || @optionsError() || @hierarchyError()
      @valid = ko.computed => !@error()

    hasName: => $.trim(@name()).length > 0

    hasCode: => $.trim(@code()).length > 0

    addOption: (option) =>
      option.id @nextId
      @options.push option
      @nextId += 1

    buttonClass: =>
      FIELD_TYPES[@kind()]

    setHierarchy: (hierarchy) =>
      @hierarchy(hierarchy)
      @initHierarchyItems()
      @uploadingHierarchy(false)
      @errorUploadingHierarchy(false)

    initHierarchyItems: =>
      @hierarchyItems = ko.observableArray $.map(@hierarchy(), (x) -> new HierarchyItem(x))

    toJSON: =>
      @code(@code().trim())
      json =
        id: @id()
        name: @name()
        code: @code()
        kind: @kind()
        ord: @ord()
      json.config = {options: $.map(@options(), (x) -> x.toJSON()), next_id: @nextId} if @isOptionsKind()
      json.config = {hierarchy: @hierarchy()} if @kind() == 'hierarchy'
      json

