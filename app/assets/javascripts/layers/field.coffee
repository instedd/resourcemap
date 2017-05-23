onLayers ->
  class @Field
    constructor: (layer, data) ->
      @layer = ko.observable layer
      @id = ko.observable data?.id
      @name = ko.observable data?.name
      @code = ko.observable data?.code
      @kind = ko.observable data?.kind
      @config = data?.config
      @metadata = data?.metadata
      @attributes = if @metadata
                      ko.observableArray($.map(@metadata, (x) -> new Attribute(x)))
                    else
                      ko.observableArray()
      @advancedExpanded = ko.observable false


      @kind_titleize = ko.computed =>
        (@kind().split(/_/).map (word) -> word[0].toUpperCase() + word[1..-1].toLowerCase()).join ' '
      @ord = ko.observable data?.ord

      @hasFocus = ko.observable(false)
      @isNew = ko.computed =>  !@id()?

      @fieldErrorDescription = ko.computed => if @hasName() then "'#{@name()}'" else "number #{@layer().fields().indexOf(@) + 1}"

      # Tried doing "@impl = ko.computed" but updates were triggering too often
      @impl = ko.observable eval("new Field_#{@kind()}(this)")
      @kind.subscribe => @impl eval("new Field_#{@kind()}(this)")

      @nameError = ko.computed => if @hasName() then null else "the field #{@fieldErrorDescription()} is missing a Name"
      @codeError = ko.computed =>
        if !@hasCode() then return "the field #{@fieldErrorDescription()} is missing a Code"
        if (@code() in ['lat', 'long', 'name', 'resmap-id', 'last updated']) then return "the field #{@fieldErrorDescription()} code is reserved"
        null

      @error = ko.computed => @nameError() || @codeError() || @impl().error()
      @valid = ko.computed => !@error()

      @initAutocompleteCodeFromName()

    initAutocompleteCodeFromName: =>
      # It works like this:
      #   1. It starts enabled if the code is empty.
      #   2. It remains enabled as long as the used doesn't modify the code manually
      #   3. It is re-enabled if the user clears the code
      @autocompleteCode = ko.observable($.trim(@code()).length == 0)

      codeAutomaticallyChanged = false

      @name.subscribe =>
        if @autocompleteCode()
          codeAutomaticallyChanged = true
          @code($.trim(@name()).toLowerCase().replace(/\W/g, '_'))
          codeAutomaticallyChanged = false

      @code.subscribe =>
        unless codeAutomaticallyChanged
          @autocompleteCode($.trim(@code()).length == 0)

    hasName: => $.trim(@name()).length > 0

    hasCode: => $.trim(@code()).length > 0

    selectingLayerClick: =>
      @switchMoveToLayerElements true

    selectingLayerSelect: =>
      return unless @selecting

      if window.model.currentLayer() != @layer()
        $("a[id='#{@code()}']").html("Move to layer '#{@layer().name()}' upon save")
      else
        $("a[id='#{@code()}']").html('Move to layer...')
      @switchMoveToLayerElements false

    switchMoveToLayerElements: (v) =>
      $("a##{@code()}").toggle()
      $("select[id='#{@code()}']").toggle()
      @selecting = v

    buttonClass: =>
      FIELD_TYPES[@kind()].css_class

    iconClass: =>
      FIELD_TYPES[@kind()].small_css_class

    toggleAdvancedExpanded: =>
      @advancedExpanded(not @advancedExpanded())

    addAttribute: (attribute) =>
      @attributes.push attribute

    toJSON: =>
      @code(@code().trim())
      json =
        id: @id()
        name: @name()
        code: @code()
        kind: @kind()
        ord: @ord()
        layer_id: @layer().id()
      @impl().toJSON(json)
      json.metadata = $.map(@attributes(), (x) -> x.toJSON())
      json

  class @FieldImpl
    constructor: (field) ->
      @field = field
      @error = -> null

    toJSON: (json) =>

  class @Field_text extends @FieldImpl

  class @Field_numeric extends @FieldImpl
    constructor: (field) ->
      super(field)

      @allowsDecimals = ko.observable field?.config?.allows_decimals == 'true'

    toJSON: (json) =>
      json.config = {allows_decimals: @allowsDecimals()}

  class @Field_yes_no extends @FieldImpl

  class @FieldSelect extends @FieldImpl
    constructor: (field) ->
      super(field)
      @options = if field.config?.options?
                   ko.observableArray($.map(field.config.options, (x) -> new Option(x)))
                 else
                   ko.observableArray()
      @nextId = field.config?.next_id || @options().length + 1
      @error = ko.computed =>
        if @options().length > 0
          codes = []
          labels = []
          for option in @options()
            return "duplicated option code '#{option.code()}' for field #{@field.name()}" if codes.indexOf(option.code()) >= 0
            return "duplicated option label '#{option.label()}' for field #{@field.name()}" if labels.indexOf(option.label()) >= 0
            codes.push option.code()
            labels.push option.label()
          null
        else
          "the field '#{@field.name()}' must have at least one option"

    addOption: (option) =>
      option.id @nextId
      @options.push option
      @nextId += 1

    toJSON: (json) =>
      json.config = {options: $.map(@options(), (x) -> x.toJSON()), next_id: @nextId}

  class @Field_select_one extends @FieldSelect
    constructor: (field) ->
      super(field)

  class @Field_select_many extends @FieldSelect
    constructor: (field) ->
      super(field)

  class @Field_hierarchy extends @FieldImpl
    constructor: (field) ->
      super(field)
      @hierarchy = ko.observable field.config?.hierarchy
      @uploadingHierarchy = ko.observable(false)
      @errorUploadingHierarchy = ko.observable(false)
      @hierarchyItems = ko.observableArray()
      @initHierarchyItems() if @hierarchy()
      @error = ko.computed =>
        if @hierarchy() && @hierarchy().length > 0
          null
        else
          "the field #{@field.fieldErrorDescription()} is missing the Hierarchy"

    setHierarchy: (hierarchy) =>
      @hierarchy(hierarchy)
      @initHierarchyItems()
      @uploadingHierarchy(false)
      @errorUploadingHierarchy(false)

    initHierarchyItems: =>
      @hierarchyItems($.map(@hierarchy(), (x) -> new HierarchyItem(x)))

    toJSON: (json) =>
      json.config = {hierarchy: @hierarchy()}

  class @Field_date extends @FieldImpl
    constructor: (field) ->
      super(field)

      @format = ko.observable field.config?.format || 'mm_dd_yyyy'

    toJSON: (json) =>
      json.config =
        format: @format()

  class @Field_site extends @FieldImpl

  class @Field_user extends @FieldImpl

  class @Field_image_gallery extends @FieldImpl
