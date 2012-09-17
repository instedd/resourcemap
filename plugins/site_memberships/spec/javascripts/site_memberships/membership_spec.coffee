describe 'Site memberships plugin', ->
  beforeEach ->
    window.runOnCallbacks 'siteMemberships'
    @field = id: 2, name: 'Director'
    @collectionId = 1
    @membership = new Membership @field, collection_id: @collectionId

  describe 'Membership', ->
    it 'should have field', ->
      expect(@membership.field).toEqual @field
 
    describe 'update access permission', ->
      beforeEach ->
        spyOn($, 'post')

      it 'should set view access', ->
        @membership.canView(true)
        expect($.post).toHaveBeenCalledWith "/plugin/site_memberships/collections/#{@collectionId}/site_memberships/set_access", access: true, type: 'view_access', field_id: @field.id

      it 'should set update access', ->
        @membership.canUpdate(true)
        expect($.post).toHaveBeenCalledWith "/plugin/site_memberships/collections/#{@collectionId}/site_memberships/set_access", access: true, type: 'update_access', field_id: @field.id

      it 'should set delete access', ->
        @membership.canDelete(true)
        expect($.post).toHaveBeenCalledWith "/plugin/site_memberships/collections/#{@collectionId}/site_memberships/set_access", access: true, type: 'delete_access', field_id: @field.id

    describe 'access permission UI', ->
      beforeEach ->
        @membership.canView(true)

      it 'should render read access UI', ->
        expect(@membership.canViewUI()).toEqual 'Yes'

      it 'should render update access UI', ->
        expect(@membership.canUpdateUI()).toEqual 'No'

      it 'should render delete access UI', ->
        expect(@membership.canDeleteUI()).toEqual 'No'
