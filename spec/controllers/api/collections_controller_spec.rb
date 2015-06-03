require 'spec_helper'

describe Api::CollectionsController, :type => :controller do
  include Devise::TestHelpers
  render_views

  let(:user) { User.make }
  let(:collection) { user.create_collection(Collection.make) }
  let(:layer) { collection.layers.make }

  describe "List" do
    before(:each) { sign_in user; collection }

    it "returns collections the user is a member of" do
      get :index,  format: 'json'

      expect(response).to be_success

      json = JSON.parse(response.body).map &:with_indifferent_access

      expect(json.length).to eq(1)
      c = json.first
      expect(c[:id]).to eq(collection.id)
    end
  end

  describe "Create" do
    it "should allow user to create a new collection" do
      sign_in user
      post :create, format: 'json', :collection => { :name => "My new collection" }
      expect(response).to be_success
    end
  end

  describe "All fields" do
    let(:text) { layer.text_fields.make :code => 'text'}
    let(:numeric) { layer.numeric_fields.make :code => 'numeric' }
    let(:yes_no) { layer.yes_no_fields.make :code => 'yes_no'}
    let(:select_one) { layer.select_one_fields.make :code => 'select_one', :config => {'options' => [{'id' => 1, 'code' => 'one', 'label' => 'One'}, {'id' => 2, 'code' => 'two', 'label' => 'Two'}]} }
    let(:select_many) { layer.select_many_fields.make :code => 'select_many', :config => {'options' => [{'id' => 1, 'code' => 'one', 'label' => 'One'}, {'id' => 2, 'code' => 'two', 'label' => 'Two'}]} }
    config_hierarchy = [{ id: 'dad', name: 'Dad', sub: [{id: 'son', name: 'Son'}, {id: 'bro', name: 'Bro'}]}]
    let(:hierarchy) { layer.hierarchy_fields.make :code => 'hierarchy',  config: { hierarchy: config_hierarchy }.with_indifferent_access }
    let(:site_ref) { layer.site_fields.make :code => 'site' }
    let(:date) { layer.date_fields.make :code => 'date' }
    let(:director) { layer.user_fields.make :code => 'user'}

    let!(:site) { collection.sites.make  :name => "Site B", :properties => {
      text.es_code => 'foo',
      numeric.es_code => 1,
      yes_no.es_code => true,
      select_one.es_code => 1,
      select_many.es_code => [1, 2],
      hierarchy.es_code => 'dad',
      site_ref.es_code => site2.id,
      date.es_code => "2012-10-24T00:00:00Z",
      director.es_code => user.email }
    }

    let!(:site2) {collection.sites.make :name => "Site A", properties: { hierarchy.es_code => 'bro' } }

    before(:each) { sign_in user }

    describe "Collection filters" do

      it "should find both sites by name" do
        pending("Filter by name with whitespaces is failling")
        get :show, id: collection.id, format: 'json', sitename: 'Site '

        json = JSON.parse response.body
        expect(json['sites'].length).to eq(2)
        expect(["Site A", "Site B"]).to include(json['sites'][0]["name"])
        expect(["Site A", "Site B"]).to include(json['sites'][1]["name"])
      end

      ['Site A', 'Site B'].each do |sitename|
        it "should find '#{sitename}' by name" do
          pending("Filter by name with whitespaces is failling")
          get :show, id: collection.id, format: 'json', sitename: sitename

          json = JSON.parse response.body
          expect(json['sites'].length).to eq(1)
          expect(json['sites'][0]["name"]).to eq(sitename)
        end
      end

      it "should not find sites when filtering with non-matching names" do
        get :show, id: collection.id, format: 'json', sitename: 'None like this'

        json = JSON.parse response.body
        expect(json['sites']).to be_empty
      end
    end

    describe "GET JSON collection" do
      before(:each) do
        get :show, id: collection.id, format: 'json', locale: 'en'
      end

      it { expect(response).to be_success }

      it "should return JSON" do
        json = JSON.parse response.body
        expect(json["name"]).to eq(collection.name)
        json['sites'].sort_by! { |site| site["name"] }
        expect(json["sites"].length).to eq(2)

        expect(json["sites"][0]["id"]).to eq(site2.id)
        expect(json["sites"][0]["name"]).to eq(site2.name)
        expect(json["sites"][0]["lat"]).to eq(site2.lat)
        expect(json["sites"][0]["long"]).to eq(site2.lng)

        expect(json["sites"][0]["properties"].length).to eq(1)

        expect(json["sites"][0]["properties"][hierarchy.code]).to eq("bro")

        expect(json["sites"][1]["id"]).to eq(site.id)
        expect(json["sites"][1]["name"]).to eq(site.name)
        expect(json["sites"][1]["lat"]).to eq(site.lat)
        expect(json["sites"][1]["long"]).to eq(site.lng)

        expect(json["sites"][1]["properties"].length).to eq(9)

        expect(json["sites"][1]["properties"][text.code]).to eq(site.properties[text.es_code])
        expect(json["sites"][1]["properties"][yes_no.code]).to be_truthy
        expect(json["sites"][1]["properties"][numeric.code]).to eq(site.properties[numeric.es_code])
        expect(json["sites"][1]["properties"][select_one.code]).to eq('one')
        expect(json["sites"][1]["properties"][select_many.code]).to eq(['one', 'two'])
        expect(json["sites"][1]["properties"][hierarchy.code]).to eq("dad")
        expect(json["sites"][1]["properties"][site_ref.code]).to eq(site2.id)
        expect(json["sites"][1]["properties"][date.code]).to eq('10/24/2012')
        expect(json["sites"][1]["properties"][director.code]).to eq(user.email)

      end
    end

    describe "GET JSON collection with query fieldeters" do
      it "should retrieve sites under certain item in a hierarchy field" do
        get :show, id: collection.id, format: 'json', hierarchy.code => { under: 'Dad' }
        expect(response).to be_success
        json = JSON.parse response.body
        expect(json["sites"].length).to eq(2)
        expect(json["sites"][0]["id"]).to eq(site2.id)
        expect(json["sites"][1]["id"]).to eq(site.id)
      end
    end

    context "location missing" do
      let!(:site1) { collection.sites.make :name => 'b', :lat => "", :lng => ""  }
      let!(:site2) { collection.sites.make :name => 'a' }

      it "should filter sites without location" do
        get :show, id: collection.id, format: 'json', "location_missing"=>"true"

        expect(response).to be_success
        json = JSON.parse response.body
        expect(json["sites"].length).to eq(1)
        expect(json["sites"][0]["name"]).to eq("b")
      end
    end

    describe "GET RSS collection" do
      before(:each) do
        get :show, id: collection.id, format: 'rss'
      end

      it { expect(response).to be_success }

      it "should return RSS" do
        rss =  Hash.from_xml response.body

        expect(rss["rss"]["channel"]["title"]).to eq(collection.name)
        rss["rss"]["channel"]["item"].sort_by! { |item| item["name"] }

        expect(rss["rss"]["channel"]["item"][0]["title"]).to eq(site2.name)
        expect(rss["rss"]["channel"]["item"][0]["lat"]).to eq(site2.lat.to_s)
        expect(rss["rss"]["channel"]["item"][0]["long"]).to eq(site2.lng.to_s)
        expect(rss["rss"]["channel"]["item"][0]["guid"]).to eq(api_site_url site2, format: 'rss')

        #TODO: This is returning "properties"=>"\n      "
        expect(rss["rss"]["channel"]["item"][0]["properties"].length).to eq(1)

        expect(rss["rss"]["channel"]["item"][0]["properties"][hierarchy.code]).to eq('bro')

        expect(rss["rss"]["channel"]["item"][1]["title"]).to eq(site.name)
        expect(rss["rss"]["channel"]["item"][1]["lat"]).to eq(site.lat.to_s)
        expect(rss["rss"]["channel"]["item"][1]["long"]).to eq(site.lng.to_s)
        expect(rss["rss"]["channel"]["item"][1]["guid"]).to eq(api_site_url site, format: 'rss')


        expect(rss["rss"]["channel"]["item"][1]["properties"].length).to eq(9)

        expect(rss["rss"]["channel"]["item"][1]["properties"][text.code]).to eq(site.properties[text.es_code])
        expect(rss["rss"]["channel"]["item"][1]["properties"][numeric.code]).to eq(site.properties[numeric.es_code].to_s)
        expect(rss["rss"]["channel"]["item"][1]["properties"][yes_no.code]).to eq('true')
        expect(rss["rss"]["channel"]["item"][1]["properties"][select_one.code]).to eq('one')
        expect(rss["rss"]["channel"]["item"][1]["properties"][select_many.code].length).to eq(1)
        expect(rss["rss"]["channel"]["item"][1]["properties"][select_many.code]['option'].length).to eq(2)
        expect(rss["rss"]["channel"]["item"][1]["properties"][select_many.code]['option'][0]['code']).to eq('one')
        expect(rss["rss"]["channel"]["item"][1]["properties"][select_many.code]['option'][1]['code']).to eq('two')
        expect(rss["rss"]["channel"]["item"][1]["properties"][hierarchy.code]).to eq('dad')
        expect(rss["rss"]["channel"]["item"][1]["properties"][site_ref.code]).to eq(site2.id.to_s)
        expect(rss["rss"]["channel"]["item"][1]["properties"][date.code]).to eq('10/24/2012')
        expect(rss["rss"]["channel"]["item"][1]["properties"][director.code]).to eq(user.email)
      end
    end

    describe "GET CSV collection" do
      before(:each) do
        get :show, id: collection.id, format: 'csv'
      end

      it { expect(response).to be_success }

      it "should return CSV" do
        csv =  CSV.parse response.body
        expect(csv.length).to eq(3)

        expect(csv[0]).to eq(['resmap-id', 'name', 'lat', 'long', text.code, numeric.code, yes_no.code, select_one.code, select_many.code, hierarchy.code,"#{hierarchy.code}-1", "#{hierarchy.code}-2", site_ref.code, date.code, director.code, 'last updated'])
        expect(csv).to include [site2.id.to_s, site2.name, site2.lat.to_s, site2.lng.to_s, "", "", "no", "", "", "bro", "Dad", "Bro", "", "", "", site2.updated_at.to_datetime.rfc822]
        expect(csv).to include [site.id.to_s, site.name, site.lat.to_s, site.lng.to_s, site.properties[text.es_code], site.properties[numeric.es_code].to_s, 'yes', 'one', 'one, two', 'dad', 'Dad', '', site2.id.to_s, '10/24/2012', user.email, site.updated_at.to_datetime.rfc822]
      end
    end

    describe "GET CSV collection according permissions" do
      let!(:member) { User.make }
      let!(:membership) { collection.memberships.create! :user_id => member.id, admin: false }
      let!(:layer_member_none) { LayerMembership.make layer: layer, membership: membership, read: false }

      before(:each) do
        sign_out user
        sign_in member
        get :show, id: collection.id, format: 'csv'
      end

      it "should not get fields without read permission" do
        csv =  CSV.parse response.body
        expect(csv.length).to eq(3)
        expect(csv[0]).to eq(['resmap-id', 'name', 'lat', 'long', 'last updated'])
        expect(csv).to include [site2.id.to_s, site2.name, site2.lat.to_s, site2.lng.to_s, site2.updated_at.to_datetime.rfc822]
        expect(csv).to include [site.id.to_s, site.name, site.lat.to_s, site.lng.to_s, site.updated_at.to_datetime.rfc822]
      end
    end

    describe "validate query fields" do
      it "should validate numeric fields in equal queries" do
        get :show, id: collection.id, format: 'csv', numeric.code => "invalid"
        expect(response.response_code).to be(400)
        expect(response.body).to include("Invalid numeric value in field numeric")
        get :show, id: collection.id, format: 'csv', numeric.code => "2"
        expect(response.response_code).to be(200)
      end

      it "should validate numeric fields in other operations" do
        get :show, id: collection.id, format: 'csv', numeric.code => "<=invalid"
        expect(response.response_code).to be(400)
        expect(response.body).to include("Invalid numeric value in field numeric")
        get :show, id: collection.id, format: 'csv', numeric.code => "<=2"
        expect(response.response_code).to be(200)
      end

      it "should validate date fields format" do
        get :show, id: collection.id, format: 'csv', date.code => "invalid1234"
        expect(response.response_code).to be(400)
        expect(response.body).to include("Invalid date value in field date")
      end

      it "should validate date fields format values" do
        get :show, id: collection.id, format: 'csv', date.code => "32/4,invalid"
        expect(response.response_code).to be(400)
        expect(response.body).to include("Invalid date value in field date")
        get :show, id: collection.id, format: 'csv', date.code => "12/25/2012,12/31/2012"
        expect(response.response_code).to be(200)
      end

      it "should validate hierarchy existing option" do
        get :show, id: collection.id, format: 'csv', hierarchy.code => ["invalid"]
        expect(response.response_code).to be(400)
        expect(response.body).to include("Invalid hierarchy option invalid in field hierarchy")
        get :show, id: collection.id, format: 'csv', hierarchy.code => ["Dad"]
        expect(response.response_code).to be(200)
      end

      it "should validate select_one existing option" do
        get :show, id: collection.id, format: 'csv', select_one.code => "invalid"
        expect(response.response_code).to be(400)
        expect(response.body).to include("Invalid option in field select_one")
        get :show, id: collection.id, format: 'csv', select_one.code => "one"
        expect(response.response_code).to be(200)
      end

      it "should validate select_many existing option" do
        get :show, id: collection.id, format: 'csv', select_many.code => "invalid"
        expect(response.response_code).to be(400)
        expect(response.body).to include("Invalid option in field select_many")
        get :show, id: collection.id, format: 'csv', select_many.code => "one"
        expect(response.response_code).to be(200)
      end
    end

    describe "GET JSON histogram" do
      it "should get histogram for a collection hierarchy field by id" do
        get :histogram_by_field, collection_id: collection.id, field_id: hierarchy.id
        expect(response).to be_success
        histogram = JSON.parse response.body
        expect(histogram['dad']).to eq(1)
        expect(histogram['bro']).to eq(1)
      end

      it "should get histogram for a collection hierarchy field by code" do
        get :histogram_by_field, collection_id: collection.id, field_id: hierarchy.code
        expect(response).to be_success
        histogram = JSON.parse response.body
        expect(histogram['dad']).to eq(1)
        expect(histogram['bro']).to eq(1)
      end

      it "should get histogram for a collection text field" do
        site3 = collection.sites.make properties: {text.es_code => 'foo'}

        get :histogram_by_field, collection_id: collection.id, field_id: text.id
        expect(response).to be_success
        histogram = JSON.parse response.body
        expect(histogram['foo']).to eq(2)
      end
    end

    describe 'bulk update' do
      it "updates sites" do
        post :bulk_update, id: collection.id, updates: { properties: { numeric.code => 3 } }
        Site.all.each do |site|
          expect(site.properties[numeric.es_code]).to eq(3)
        end
      end

      it "should update name, latitude and longitude" do
        post :bulk_update, id: collection.id, updates: { name: 'New name', lat: 35.2, lng: -25 }
        Site.all.each do |site|
          expect(site.name).to eq('New name')
          expect(site.lat).to eq(35.2)
          expect(site.lng).to eq(-25)
        end
      end

      it "should only update according to filters" do
        post :bulk_update, id: collection.id, site_id: site.id, updates: { name: 'New name' }
        expect(site.reload.name).to eq('New name')
        expect(site2.reload.name).not_to eq('New name')

        post :bulk_update, id: collection.id, text.code => 'foo', updates: { name: 'New name' }
        expect(site.reload.name).to eq('New name')
        expect(site2.reload.name).not_to eq('New name')
      end
    end
  end

  describe "Filter by name" do
    let(:text) { layer.text_fields.make :code => 'text'}
    let(:numeric) { layer.numeric_fields.make :code => 'numeric' }
    let(:yes_no) { layer.yes_no_fields.make :code => 'yes_no'}
    let(:select_one) { layer.select_one_fields.make :code => 'select_one', :config => {'options' => [{'id' => 1, 'code' => 'one', 'label' => 'One'}, {'id' => 2, 'code' => 'two', 'label' => 'Two'}]} }
    let(:select_many) { layer.select_many_fields.make :code => 'select_many', :config => {'options' => [{'id' => 1, 'code' => 'one', 'label' => 'One'}, {'id' => 2, 'code' => 'two', 'label' => 'Two'}]} }
    config_hierarchy = [{ id: 'dad', name: 'Dad', sub: [{id: 'son', name: 'Son'}, {id: 'bro', name: 'Bro'}]}]
    let(:hierarchy) { layer.hierarchy_fields.make :code => 'hierarchy',  config: { hierarchy: config_hierarchy }.with_indifferent_access }
    let(:site_ref) { layer.site_fields.make :code => 'site' }
    let(:date) { layer.date_fields.make :code => 'date' }
    let(:director) { layer.user_fields.make :code => 'user'}

    let!(:site) { collection.sites.make  :name => "Site_B", :properties => {
      text.es_code => 'foo',
      numeric.es_code => 1,
      yes_no.es_code => true,
      select_one.es_code => 1,
      select_many.es_code => [1, 2],
      hierarchy.es_code => 'dad',
      site_ref.es_code => site2.id,
      date.es_code => "2012-10-24T00:00:00Z",
      director.es_code => user.email }
    }

    let!(:site2) {collection.sites.make :name => "Site_A", properties: { hierarchy.es_code => 'bro' } }

    before(:each) { sign_in user }

    it "should find both sites by name" do
      get :show, id: collection.id, format: 'json', sitename: 'Site_'

      json = JSON.parse response.body
      expect(json['sites'].length).to eq(2)
      expect(["Site_A", "Site_B"]).to include(json['sites'][0]["name"])
      expect(["Site_A", "Site_B"]).to include(json['sites'][1]["name"])
    end

    ['Site_A', 'Site_B'].each do |sitename|
      it "should find '#{sitename}' by name" do
        get :show, id: collection.id, format: 'json', sitename: sitename

        json = JSON.parse response.body
        expect(json['sites'].length).to eq(1)
        expect(json['sites'][0]["name"]).to eq(sitename)
      end
    end

    it "should not find sites when filtering with non-matching names" do
      get :show, id: collection.id, format: 'json', sitename: 'None like this'

      json = JSON.parse response.body
      expect(json['sites']).to be_empty
    end
  end

  describe "Date fields" do
    let(:date_mdy) { layer.date_fields.make :code => 'date_mdy', config:  {'format' => 'mm_dd_yyyy'} }
    let(:date_dmy) { layer.date_fields.make :code => 'date_dmy', config:  {'format' => 'dd_mm_yyyy'} }

    let!(:site_A) {collection.sites.make :name => "Site A", properties: { date_mdy.es_code => "2012-10-24T00:00:00Z", date_dmy.es_code => "2012-10-24T00:00:00Z" } }

    before(:each) { sign_in user }

    describe "get dates fields in the right format"  do
      it "should get CSV with right date format" do
        get :show, id: collection.id, format: 'csv'
        csv =  CSV.parse response.body
        expect(csv[0]).to eq(['resmap-id', 'name', 'lat', 'long', 'date_mdy', 'date_dmy', 'last updated'])
        expect(csv).to include [site_A.id.to_s, site_A.name, site_A.lat.to_s, site_A.lng.to_s, '10/24/2012', '24/10/2012' ,site_A.updated_at.to_datetime.rfc822]
      end

      it "should get JSON with right date format" do
        get :show, id: collection.id, format: 'json'
        json = JSON.parse response.body
        expect(json["name"]).to eq(collection.name)
        expect(json["sites"].length).to eq(1)

        expect(json["sites"][0]["id"]).to eq(site_A.id)
        expect(json["sites"][0]["name"]).to eq(site_A.name)
        expect(json["sites"][0]["lat"]).to eq(site_A.lat)
        expect(json["sites"][0]["long"]).to eq(site_A.lng)

        expect(json["sites"][0]["properties"].length).to eq(2)
        expect(json["sites"][0]["properties"][date_mdy.code]).to eq("10/24/2012")
        expect(json["sites"][0]["properties"][date_dmy.code]).to eq("24/10/2012")
      end

      it "should get RSS with right date format" do
        get :show, id: collection.id, format: 'rss'
        rss =  Hash.from_xml response.body
        expect(rss["rss"]["channel"]["title"]).to eq(collection.name)

        expect(rss["rss"]["channel"]["item"]["lat"]).to eq(site_A.lat.to_s)
        expect(rss["rss"]["channel"]["item"]["long"]).to eq(site_A.lng.to_s)

        expect(rss["rss"]["channel"]["item"]["properties"].length).to eq(2)
        expect(rss["rss"]["channel"]["item"]["properties"][date_mdy.code]).to eq("10/24/2012")
        expect(rss["rss"]["channel"]["item"]["properties"][date_dmy.code]).to eq("24/10/2012")
      end
    end
  end

  describe "gets sites by id" do
    before(:each) { sign_in user }

    it "gets site by id" do
      sites = 6.times.map { collection.sites.make }

      site_id = sites[0].id
      get :show, id: collection.id, site_id: site_id, format: :json

      expect(response).to be_ok

      collection = JSON.parse response.body
      expect(collection["sites"].map { |s| s["id"] }).to eq([site_id])
    end

    it "gets sites by id" do
      sites = 6.times.map { collection.sites.make }
      site_ids = [sites[0].id, sites[2].id, sites[5].id]

      get :show, id: collection.id, site_id: site_ids, format: :json

      expect(response).to be_ok

      collection = JSON.parse response.body
      expect(collection["sites"].map { |s| s["id"] }.sort).to eq(site_ids)
    end

    it "gets sites by id, paged" do
      sites = 6.times.map { collection.sites.make }
      site_ids = [sites[0].id, sites[2].id, sites[3].id, sites[5].id]

      get :show, id: collection.id, site_id: site_ids, page: 1, page_size: 2, format: :json

      expect(response).to be_ok

      json = JSON.parse response.body
      first_ids = json["sites"].map { |s| s["id"] }
      expect(first_ids.length).to eq(2)

      get :show, id: collection.id, site_id: site_ids, page: 2, page_size: 2, format: :json

      expect(response).to be_ok

      json = JSON.parse response.body
      second_ids = json["sites"].map { |s| s["id"] }
      expect(second_ids.length).to eq(2)

      expect((first_ids + second_ids).sort).to eq(site_ids)
    end
  end

  describe "destroy" do
    it "destroys a collection" do
      sign_in user
      delete :destroy, id: collection.id
      expect(response).to be_ok
      expect(Collection.count).to eq(0)
    end

    it "destroys a collection and its User Snapshots" do
      collection.snapshots.create! date: Time.now, name: 'last_hour'
      UserSnapshot.for(user, collection).save

      expect(UserSnapshot.count).to eq(1)

      sign_in user
      delete :destroy, id: collection.id

      expect(response).to be_ok
      expect(UserSnapshot.count).to eq(0)
      expect(Collection.count).to eq(0)
    end

    it "doesnt allow a non-admin member to destroy a collection" do
      user2 = User.make
      collection.memberships.create! :user_id => user2.id, admin: false
      sign_in user2

      delete :destroy, id: collection.id

      expect(response.code).to eq("403")
      expect(Collection.count).to eq(1)
    end
  end

  it "returns names for select one and many and hierarchies with human flag" do
    sign_in user
    layer = collection.layers.make
    select_one = layer.select_one_fields.make :code => 'select_one', :config => {'next_id' => 3, 'options' => [{'id' => 1, 'code' => 'one', 'label' => 'One'}, {'id' => 2, 'code' => 'two', 'label' => 'Two'}]}
    select_many = layer.select_many_fields.make :code => 'select_many', :config => {'next_id' => 3, 'options' => [{'id' => 1, 'code' => 'one', 'label' => 'One'}, {'id' => 2, 'code' => 'two', 'label' => 'Two'}]}
    config_hierarchy = [{ id: '60', name: 'Dad', sub: [{id: '100', name: 'Son'}, {id: '101', name: 'Bro'}]}]
    hierarchy_field = layer.hierarchy_fields.make :code => 'hierarchy', config: { hierarchy: config_hierarchy }.with_indifferent_access

    collection.sites.make name: 'TallLand', properties: { select_one.es_code => 2, select_many.es_code => [1,2], hierarchy_field.es_code => '100' }

    get :show, id: collection.id, human: true,  format: 'json'
    expect(response).to be_success
    json = JSON.parse response.body
    expect(json["sites"].first["properties"]['select_one']).to eq('Two')
    expect(json["sites"].first["properties"]['select_many']).to eq('One, Two')
    expect(json["sites"].first["properties"]['hierarchy']).to eq('Dad - Son')
  end

  it "returns codes for select one, many and hierarchies without human flag" do
    sign_in user
    layer = collection.layers.make
    select_one = layer.select_one_fields.make :code => 'select_one', :config => {'next_id' => 3, 'options' => [{'id' => 1, 'code' => 'one', 'label' => 'One'}, {'id' => 2, 'code' => 'two', 'label' => 'Two'}]}
    select_many = layer.select_many_fields.make :code => 'select_many', :config => {'next_id' => 3, 'options' => [{'id' => 1, 'code' => 'one', 'label' => 'One'}, {'id' => 2, 'code' => 'two', 'label' => 'Two'}]}
    config_hierarchy = [{ id: '60', name: 'Dad', sub: [{id: '100', name: 'Son'}, {id: '101', name: 'Bro'}]}]
    hierarchy_field = layer.hierarchy_fields.make :code => 'hierarchy', config: { hierarchy: config_hierarchy }.with_indifferent_access

    collection.sites.make name: 'TallLand', properties: { select_one.es_code => 2, select_many.es_code => [1,2], hierarchy_field.es_code => '100' }

    get :show, id: collection.id, format: 'json'
    expect(response).to be_success
    json = JSON.parse response.body
    expect(json["sites"].first["properties"]['select_one']).to eq('two')
    expect(json["sites"].first["properties"]['select_many']).to eq(['one', 'two'])
    expect(json["sites"].first["properties"]['hierarchy']).to eq('100')

    get :show, id: collection.id, human: false, format: 'json'
    expect(response).to be_success
    json = JSON.parse response.body
    expect(json["sites"].first["properties"]['select_one']).to eq('two')
    expect(json["sites"].first["properties"]['select_many']).to eq(['one', 'two'])
    expect(json["sites"].first["properties"]['hierarchy']).to eq('100')
  end

end
