onThresholds ->
  class @Threshold
    constructor: (data) ->
      @id = ko.observable data?.id
      @collectionId = data?.collection_id
      @isAllSite = ko.observable data?.is_all_site.toString()
      @isAllCondition = ko.observable data?.is_all_condition.toString()
      @isNotify = ko.observable data?.is_notify.toString()
      @messageNotification = ko.observable data?.message_notification
    
      @fieldsEmail  = ko.observableArray data?.email_notification["fields"] ? []
      @usersEmail   = ko.observableArray data?.email_notification["users"] ? []
      @membersEmail = ko.observableArray data?.email_notification["members"] ? []

      @fieldsPhone  = ko.observableArray data?.phone_notification["fields"] ? []
      @usersPhone   = ko.observableArray data?.phone_notification["users"] ? []
      @membersPhone = ko.observableArray data?.phone_notification["members"] ? []

      @alertSites = ko.observable $.map(data?.sites ? [], (site) -> new Site(site))
      @propertyName = ko.observable data?.property_name
      @ord = ko.observable data?.ord
      # @color = ko.observable(data?.color ? '#ff0000')
      @icon = ko.observable(data.icon ? "marker_red.png")
      @iconUrl = ko.computed => "/assets/#{@icon()}"
      @conditions = ko.observableArray $.map(data?.conditions ? [], (condition) -> new Condition(condition))
      @propertyNameError = ko.computed =>
        if $.trim(@propertyName()).length > 0
          return null
        else
          return "Alert property's name is missing"
      @notificationMessageError = ko.computed =>
        if $.trim(@messageNotification()).length > 0
          return null
        else
          return "Notification's message is missing"
      @error = ko.computed =>
        return "Can't save: " + @propertyNameError() if @propertyNameError()
        return "the threshold must have at least one condition" if @conditions().length is 0
        for condition, i in @conditions()
          return "condition ##{i+1} #{condition.error()}" unless condition.valid()
        return "Can't save: " + @notificationMessageError() if @notificationMessageError()

      @valid = ko.computed => not @error()?

    addNewCondition: =>
      condition = new Condition()
      @conditions.push condition
      condition

    removeCondition: (condition) =>
      @conditions.remove condition

    isFirstCondition: (condition) ->
      0 == @conditions().indexOf condition

    isLastCondition: (condition) ->
      @conditions().length - 1 == @conditions().indexOf condition

    setOrder: (ord, callback) ->
      @ord ord
      $.post "/plugin/alerts/collections/#{@collectionId}/thresholds/#{@id()}/set_order.json", { ord: ord }, callback

    setIcon: (icon) ->
      @icon icon

    toJSON: =>
      id: @id()
      icon: @icon()
      property_name: @propertyName()
      is_all_site: @isAllSite()
      is_all_condition: @isAllCondition()
      is_notify: @isNotify()
      email_notification:
        users: @usersEmail()
        fields: @fieldsEmail()
        members: @membersEmail()
      phone_notification: 
        users: @usersPhone()
        fields: @fieldsPhone()
        members: @membersPhone()
      
      message_notification: @messageNotification()
      sites: $.map(@alertSites(), (site) -> site.toJSON())
      conditions: $.map(@conditions(), (condition) -> condition.toJSON())
      ord: @ord()


    addSiteNameToMessageNotification: =>
      @messageNotification(@messageNotification() + ' [Site Name]')

    addFieldNameToMessageNotification:(field) =>
      @messageNotification(@messageNotification() + ' [' + field.name() + ']')
