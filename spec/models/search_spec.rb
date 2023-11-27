#encoding=utf-8
require 'spec_helper'

describe Search, :type => :model do
  let!(:user) { User.make! }
  let!(:collection) { user.create_collection(Collection.make!) }
  let!(:layer) { collection.layers.make! }

  context "search by property" do
    let!(:beds) { layer.numeric_fields.make! code: 'beds' }
    let!(:tables) { layer.numeric_fields.make! code: 'tables' }
    let!(:first_name) { layer.text_fields.make! code: 'first_name' }
    let!(:country) { layer.text_fields.make! code: 'country' }
    let!(:kind) { layer.select_many_fields.make! code: 'kind', :config => {'options' => [{'id' => 1, 'code' => 'hosp', 'label' => 'Hospital'}, {'id' => 2, 'code' => 'center', 'label' => 'Health Center'}, {'id' => 3, 'code' => 'phar', 'label' => 'Pharmacy'}]} }
    let!(:hierarchy) { layer.hierarchy_fields.make! code: 'hie', config: { "hierarchy" => [{ 'id' => 1, 'name' => 'root'}, { 'id' => 2, 'name' => 'root'}] } }


    let!(:site1) { collection.sites.make! properties:
      {beds.es_code => 5, tables.es_code => 1, first_name.es_code => "peterin panini", country.es_code => "argentina", kind.es_code => [1,2]} }
    let!(:site2) { collection.sites.make! properties:
      {beds.es_code => 10, tables.es_code => 2, first_name.es_code => "peter pan", country.es_code => "albania", kind.es_code => [1,3]}  }
    let!(:site3) { collection.sites.make! properties:
      {beds.es_code => 20, tables.es_code => 3, first_name.es_code => "Alice Cooper", country.es_code => "argelia", hierarchy.es_code => 1}  }
    let!(:site4) { collection.sites.make! properties:
      {beds.es_code => 10, tables.es_code => 4, first_name.es_code => "John Doyle", country.es_code => "south arabia", hierarchy.es_code => 1, kind.es_code => [2,3]}  }

    it "searches by equality" do
      search = collection.new_search
      search.where beds.es_code => 10
      assert_results search, site2, site4
    end

    it "searches by equality with code" do
      search = collection.new_search
      search.use_codes_instead_of_es_codes
      search.where 'beds' => 10
      assert_results search, site2, site4
    end

    it "searches by equality with @code" do
      search = collection.new_search
      search.use_codes_instead_of_es_codes
      search.where '@beds' => 10
      assert_results search, site2, site4
    end

    it "searches by name equality on hierarchy field" do
      site5 = collection.sites.make! properties:
      {beds.es_code => 10, tables.es_code => 5, first_name.es_code => "John Doyle 2", country.es_code => "south arabia", hierarchy.es_code => 2}
      search = collection.new_search
      search.use_codes_instead_of_es_codes
      search.where hierarchy.code => 'root'
      assert_results search, site3, site4, site5
    end

    it "searches by equality on hierarchy field" do
      search = collection.new_search
      search.where hierarchy.es_code => [1]
      assert_results search, site3, site4
    end

    it "searches by equality of two properties" do
      search = collection.new_search
      search.where beds.es_code => 10, tables.es_code => 2
      assert_results search, site2
    end

    it "searches by equality of two properties but doesn't find" do
      search = collection.new_search
      search.where beds.es_code => 10, tables.es_code => 1
      expect(search.results.length).to eq(0)
    end

    it "searches by starts with" do
      search = collection.new_search
      search.where first_name.es_code => "~=peter"
      assert_results search, site1, site2
    end

    it "searches by starts with and equality" do
      search = collection.new_search
      search.where first_name.es_code => "~=peter"
      search.where beds.es_code => 5
      assert_results search, site1
    end

    it "searches by starts with on two different fields" do
      search = collection.new_search
      search.where first_name.es_code => "~=peter"
      search.where country.es_code => "~=arg"
      assert_results search, site1
    end

    it "searches by two comparisons on the same field" do
      search = collection.new_search
      search.where beds.es_code => "<=20"
      search.where beds.es_code => ">7"
      assert_results search, site2, site3, site4
    end

    it "searches by multiple text values" do
      search = collection.new_search
      search.where first_name.es_code => ["peter pan", "Alice Cooper"]
      assert_results search, site2, site3
    end

    it "searches by multiple numeric values" do
      search = collection.new_search
      search.where tables.es_code => [1, 3]
      assert_results search, site1, site3
    end

    it "searches by select many field accepting sites with at least the search parameter" do
      search = collection.new_search
      search.where kind.es_code => 3
      assert_results search, site2, site4
    end

    it "searches by select many on more than one value" do
      search = collection.new_search
      search.where kind.es_code => [2,3]
      assert_results search, site1, site2, site4
    end


    context "full text search" do
      let!(:population_source) { layer.text_fields.make! :code => 'population_source' }

      it "searches by equality with text" do
        a_site = collection.sites.make! :properties => {population_source.es_code => "National Census"}
        search = collection.new_search
        search.where population_source.es_code => "National Census"
        assert_results search, a_site
      end

      it "searches by equality with text doesn't confuse name" do
        a_site = collection.sites.make! :name => "Census", :properties => {population_source.es_code => "National"}
        search = collection.new_search
        search.where population_source.es_code => "National Census"
        expect(search.results.length).to eq(0)
      end
    end

    it "searches with lt" do
      search = collection.new_search
      search.lt beds, 8
      assert_results search, site1
    end

    it "searches with lte" do
      search = collection.new_search
      search.lte beds, 10
      assert_results search, site1, site2, site4
    end

    it "searches with gt" do
      search = collection.new_search
      search.gt beds, 18
      assert_results search, site3
    end

    it "searches with gte" do
      search = collection.new_search
      search.gte beds, 10
      assert_results search, site2, site3, site4
    end

    it "searches with combined properties" do
      search = collection.new_search
      search.lt beds, 11
      search.gte tables, 4
      assert_results search, site4
    end

    it "searches with ops" do
      search = collection.new_search
      search.op beds, '<', 8
      search.op tables, '>=', 1
      assert_results search, site1
    end

    context "where with op" do
      it "searches where with lt" do
        search = collection.new_search
        search.where beds.es_code => '< 8'
        assert_results search, site1
      end

      it "searches where with lte" do
        search = collection.new_search
        search.where beds.es_code => '<= 5'
        assert_results search, site1
      end

      it "searches where with gt" do
        search = collection.new_search
        search.where beds.es_code => '> 19'
        assert_results search, site3
      end

      it "searches where with gte" do
        search = collection.new_search
        search.where beds.es_code => '>= 20'
        assert_results search, site3
      end

      it "searches where with eq" do
        search = collection.new_search
        search.where beds.es_code => '= 10'
        assert_results search, site2, site4
      end
    end

    context "unknow field" do
      it "raises on unknown field" do
        search = collection.new_search
        expect { search.where '0' => 10 }.to raise_error(RuntimeError, "Unknown field: 0")
      end
    end

    it "doesn't find deleted sites" do
      site2.destroy

      search = collection.new_search
      search.where beds.es_code => 10
      assert_results search, site4
    end

    it "finds only deleted sites" do
      site2.destroy

      search = collection.new_search
      search.where beds.es_code => 10
      search.only_deleted
      assert_results search, site2
    end

    it "finds deleted and non-deleted sites" do
      site2.destroy

      search = collection.new_search
      search.where beds.es_code => 10
      search.show_deleted
      assert_results search, site2, site4
    end

    it "finds deleted since" do
      Timecop.freeze(Time.now) do
        site1.destroy

        Timecop.travel(1.day.from_now)
        site2.destroy

        Timecop.travel(1.day.from_now)
        site3.destroy

        Timecop.travel(1.day.from_now)
        site4.destroy

        Timecop.travel(1.day.from_now)

        search = collection.new_search
        search.deleted_since(49.hours.ago)
        assert_results search, site3, site4
      end
    end
  end

  context "find by id" do
    let!(:site1) { collection.sites.make! }
    let!(:site2) { collection.sites.make! }

    it "finds by id" do
      assert_results collection.new_search.id(site1.id), site1
    end
  end

  context "pagination" do
    it "paginates by 50 results by default" do
      expect(Search.new(collection, {}).page_size).to eq(50)
    end

    context "with another page size" do
      it "gets first page" do
        sites = 3.times.map { collection.sites.make! }
        sites.sort! { |s1, s2| s1.name <=> s2.name }
        search = collection.new_search
        search.page_size = 2
        assert_results search, sites[0], sites[1]
      end

      it "gets second page" do
        sites = 3.times.map { collection.sites.make! }
        sites.sort! { |s1, s2| s1.name <=> s2.name }
        search = collection.new_search
        search.page_size = 2
        assert_results search.page(2), sites[2]
      end
    end
  end

  context "after" do
    before(:each) do
      @site1 = collection.sites.make! :updated_at => (Time.now - 3.days)
      @site2 = collection.sites.make! :updated_at => (Time.now - 2.days)
      @site3 = collection.sites.make! :updated_at => (Time.now - 1.days)
    end

    it "gets results before a date" do
      assert_results collection.new_search.before(@site2.updated_at + 1.second), @site1, @site2
    end

    it "gets results before a date as string" do
      assert_results collection.new_search.before((@site2.updated_at + 1.second).to_s), @site1, @site2
    end

    it "gets results after a date" do
      assert_results collection.new_search.after(@site2.updated_at - 1.second), @site2, @site3
    end

    it "gets results after a date as string" do
      assert_results collection.new_search.after((@site2.updated_at - 1.second).to_s), @site2, @site3
    end
  end

  context "full text search" do
    let!(:layer) { collection.layers.make! }
    let!(:prop) { layer.select_one_fields.make! :code => 'prop', :config => {'options' => [{'id' => 1, 'code' => 'foo', 'label' => 'A glass of water'}, {'id' => 2, 'code' => 'bar', 'label' => 'A bottle of wine'}, {'id' => 3, 'code' => 'baz', 'label' => 'COCO'}]} }
    let!(:beds) { layer.numeric_fields.make! :code => 'beds' }
    let!(:luhn) { layer.identifier_fields.make! :code => 'luhn', :config => { 'format' => 'Luhn'} }
    let!(:site1) { collection.sites.make! :name => "Argentina", :properties => {beds.es_code => 8, prop.es_code => 1} }
    let!(:site2) { collection.sites.make! :name => "Buenos Aires", :properties => {beds.es_code => 10, prop.es_code => 2} }
    let!(:site3) { collection.sites.make! :name => "Cordoba bar Buenos", :properties => {beds.es_code => 20, prop.es_code => 3} }
    let!(:site4) { collection.sites.make! :name => "hello?/{#.", :properties => {beds.es_code => 0, prop.es_code => 3} }
    let!(:site5) { collection.sites.make! :name => "A Luhn Site", :properties => {luhn.es_code => "100001-7"} }

    # Regression test fo https://github.com/instedd/resourcemap/issues/870
    it "finds by whole luhn id" do
      search = collection.new_search.full_text_search("100001-7")
      assert_results search, site5
    end

    it "finds by luhn id prefix" do
      assert_results collection.new_search.full_text_search("100001"), site5
    end

    it "finds by name" do
      assert_results collection.new_search.full_text_search("Argent"), site1
      assert_results collection.new_search.full_text_search("Buenos"), site2, site3
    end

    it "finds by number property" do
      assert_results collection.new_search.full_text_search(8), site1
    end

    it "finds by text property" do
      assert_results collection.new_search.full_text_search("foo"), site1
    end

    it "finds by value of select one property" do
      assert_results collection.new_search.full_text_search("water"), site1
    end

    it "finds by value of select one property using where" do
      search = collection.new_search
      search.use_codes_instead_of_es_codes
      assert_results search.where(prop.code => "A glass of water"), site1
    end

    it "doesn't give false positives" do
      assert_results collection.new_search.full_text_search("wine"), site2
    end

    it "searches whole phrase, not part of it" do
      assert_results collection.new_search.full_text_search("Buenos Aires"), site2
    end

    skip "searches by name property" do
      assert_results collection.new_search.full_text_search('name:"Buenos Aires"'), site2
    end

    it "searches by numeric property" do
      assert_results collection.new_search.full_text_search('beds:8'), site1
    end

    it "searches by numeric property with comparison" do
      assert_results collection.new_search.full_text_search('beds:>=10'), site2, site3
    end

    it "searches by label value" do
      assert_results collection.new_search.full_text_search("prop:water"), site1
    end

    it "searches with written accents" do
      a_site = collection.sites.make! :name => "Censús"
      assert_results collection.new_search.full_text_search("Censús"), a_site
    end

    it "searches case-insensitive" do
      a_site = collection.sites.make! :name => "cutralco"
      assert_results collection.new_search.full_text_search("CutralCo"), a_site
    end

    it "indexes accents-insensitive" do
      colon = collection.sites.make!  name: 'colón'
      assert_results collection.new_search.full_text_search("colon"), colon
    end

    it "escapes symbols" do
      assert_results collection.new_search.full_text_search("hello?/{#."), site4
    end
  end

  context "geo" do
    let!(:site1) { collection.sites.make! lat: 10, lng: 20}
    let!(:site2) { collection.sites.make! lat: 15.321, lng: 25.123}
    let!(:site3) { collection.sites.make! lat: 40, lng: -60.1}

    it "searches by box" do
      assert_results collection.new_search.box(19, 9, 26, 16), site1, site2
    end

    it "searches by text km radius" do
      assert_results collection.new_search.radius(12.5, 22.5, '600km'), site1, site2
    end

    it "searches by text miles radius" do
      assert_results collection.new_search.radius(12.5, 22.5, '434mi'), site1, site2
    end

    it "searches by numeric radius" do
      assert_results collection.new_search.radius(12.5, 22.5, 600_000), site1, site2
    end

    it "searches by numeric radius on single site" do
      assert_results collection.new_search.radius(10, 20, 1), site1
    end

    it "full text searches by lat" do
      assert_results collection.new_search.full_text_search("15.3"), site2
      assert_results collection.new_search.full_text_search("-60.1"), site3
    end

    it "full text searches by lng" do
      assert_results collection.new_search.full_text_search("25.1"), site2
    end
  end

  context "results format" do
    let!(:text) { layer.text_fields.make! :code => 'text' }
    let!(:numeric) { layer.numeric_fields.make! :code => 'numeric' }
    let!(:select_one) { layer.select_one_fields.make! :code => 'select_one', :config => {'options' => [{'id' => 1, 'code' => 'one', 'label' => 'One'}, {'id' => 2, 'code' => 'two', 'label' => 'Two'}]} }
    let!(:select_many) { layer.select_many_fields.make! :code => 'select_many', :config => {'options' => [{'id' => 1, 'code' => 'one', 'label' => 'One'}, {'id' => 2, 'code' => 'two', 'label' => 'Two'}]} }

    let!(:site1) { collection.sites.make! :lat => 1, :lng => 2, :properties => {text.es_code => 'foo', numeric.es_code => 1, select_one.es_code => 1, select_many.es_code => [1, 2]} }

    it "gets results" do
      result = collection.new_search.results[0]
      expect(result['_source']['properties'][text.es_code]).to eq('foo')
      expect(result['_source']['properties'][numeric.es_code]).to eq(1)
      expect(result['_source']['properties'][select_one.es_code]).to eq(1)
      expect(result['_source']['properties'][select_many.es_code]).to eq([1, 2])
    end

    it "gets api results" do
      search = collection.new_search current_user_id: user.id
      result = search.api_results[0]
      expect(result['_source']['properties'][text.code]).to eq('foo')
      expect(result['_source']['properties'][numeric.code]).to eq(1)
      expect(result['_source']['properties'][select_one.code]).to eq('one')
      expect(result['_source']['properties'][select_many.code]).to eq(['one', 'two'])
    end


    it "gets api results from snapshot" do
      snapshot = collection.snapshots.create! date: Time.now, name: 'snp1'
      snapshot.user_snapshots.create! user: user

      site1.properties = {text.es_code => 'foo2', numeric.es_code => 2, select_one.es_code => 2, select_many.es_code => [2]}
      site1.save!

      search = collection.new_search current_user_id: user.id
      result = search.api_results[0]
      expect(result['_source']['properties'][text.code]).to eq('foo2')
      expect(result['_source']['properties'][numeric.code]).to eq(2)
      expect(result['_source']['properties'][select_one.code]).to eq('two')
      expect(result['_source']['properties'][select_many.code]).to eq(['two'])

      search = collection.new_search current_user_id: user.id, snapshot_id: snapshot.id
      result = search.api_results[0]
      expect(result['_source']['properties'][text.code]).to eq('foo')
      expect(result['_source']['properties'][numeric.code]).to eq(1)
      expect(result['_source']['properties'][select_one.code]).to eq('one')
      expect(result['_source']['properties'][select_many.code]).to eq(['one', 'two'])
    end

    it "gets ui results" do
      search = collection.new_search current_user_id: user.id
      result = search.ui_results[0]
      expect(result['_source']['lat']).to eq(1)
      expect(result['_source']['lng']).to eq(2)
    end

    it "gets ui form snapshot" do
      snapshot = collection.snapshots.create! date: Time.now, name: 'snp1'
      snapshot.user_snapshots.create! user: user

      site1.properties = {text.es_code => 'foo2', numeric.es_code => 2, select_one.es_code => 2, select_many.es_code => [2]}
      site1.save!

      search = collection.new_search current_user_id: user.id
      result = search.ui_results[0]

      expect(result['_source']['properties'][text.es_code]).to eq('foo2')
      expect(result['_source']['properties'][numeric.es_code]).to eq(2)
      expect(result['_source']['properties'][select_one.es_code]).to eq(2)
      expect(result['_source']['properties'][select_many.es_code]).to eq([2])

      search = collection.new_search current_user_id: user.id, snapshot_id: snapshot.id
      result = search.ui_results[0]
      expect(result['_source']['properties'][text.es_code]).to eq('foo')
      expect(result['_source']['properties'][numeric.es_code]).to eq(1)
      expect(result['_source']['properties'][select_one.es_code]).to eq(1)
      expect(result['_source']['properties'][select_many.es_code]).to eq([1, 2])
    end

    it "do not get deleted fields" do
      numeric.delete
      search = collection.new_search current_user_id: user.id
      result = search.ui_results[0]
      expect(result['_source']['properties'][numeric.es_code]).to be_nil
    end

  end

  context "sort" do
    let!(:numeric) { layer.numeric_fields.make! :code => 'numeric' }

    let!(:site2) { collection.sites.make! :name => 'Esther Goris', :properties => {numeric.es_code => 1} }
    let!(:site1) { collection.sites.make! :name => 'Brian Adams', :properties => {numeric.es_code => 2} }

    let!(:search) { collection.new_search.use_codes_instead_of_es_codes }

    it "sorts on name asc by default" do
      result = search.results
      expect(result.map { |x| x['_id'].to_i }) .to eq([site1.id, site2.id])
    end

    it "sorts by field asc" do
      result = search.sort(numeric.code).results
      expect(result.map { |x| x['_id'].to_i }) .to eq([site2.id, site1.id])
    end

    it "sorts by field desc" do
      result = search.sort(numeric.code, false).results
      expect(result.map { |x| x['_id'].to_i }) .to eq([site1.id, site2.id])
    end

    it "sorts by name asc" do
      result = search.sort('name').results
      expect(result.map { |x| x['_id'].to_i }) .to eq([site1.id, site2.id])
    end

    it "sorts by name desc" do
      result = search.sort('name', false).results
      expect(result.map { |x| x['_id'].to_i }) .to eq([site2.id, site1.id])
    end

    it "sorts by multiple fields" do
      site3 = collection.sites.make! :name => 'Esther Goris', :properties => {numeric.es_code => 2}
      result = search.sort_multiple({'name' => true, numeric.code => false}).results
      expect(result.map { |x| x['_id'].to_i }) .to eq([site1.id, site3.id, site2.id])
    end

    it "sorts by name case-insensitive" do
      site3 = collection.sites.make! :name => 'esther agoris', :properties => {numeric.es_code => 2}
      result = search.sort('name').results
      expect(result.map { |x| x['_id'].to_i }) .to eq([site1.id, site3.id, site2.id])
    end
  end

  context "location missing" do
    let!(:site1) { collection.sites.make! :name => 'b', :lat => "", :lng => ""  }
    let!(:site2) { collection.sites.make! :name => 'a' }

    it "should filter sites without location" do
      result = collection.new_search.location_missing.results
      expect(result.map { |x| x['_id'].to_i }) .to eq([site1.id])
    end

  end

  context "filter by date field range format mm/dd/yyyy" do
    let!(:creation) { layer.date_fields.make! code: 'creation' }
    let!(:inaguration) { layer.date_fields.make! code: 'inaguration' }

    let!(:site1) { collection.sites.make! :name => 'b', properties: { creation.es_code =>"2012-09-07T00:00:00Z", inaguration.es_code =>"2012-09-23T00:00:00Z"} }
    let!(:site2) { collection.sites.make! :name => 'a', properties: { creation.es_code =>"2013-09-07T00:00:00Z", inaguration.es_code =>"2012-09-23T00:00:00Z"} }

    it "should parse date from" do
      search = collection.new_search
      parameter = "12/12/2012,1/1/2013"
      date = creation.send(:parse_date_from, parameter)
      expect(date).to eq("12/12/2012")
    end

    it "should parse date to" do
      search = collection.new_search
      parameter = "12/12/2012,1/1/2013"
      date = creation.send(:parse_date_to, parameter)
      expect(date).to eq("1/1/2013")
    end

    it "should search by range" do
      search = collection.new_search
      search.where creation.es_code => "=09/06/2012,09/08/2012"
      assert_results search, site1
    end

    it "should search by specific date" do
      search = collection.new_search
      search.where inaguration.es_code => "=09/23/2012,09/23/2012"
      assert_results search, site1, site2
    end

    it "searches by date with @code" do
      search = collection.new_search
      search.use_codes_instead_of_es_codes
      search.where creation.code => "=09/06/2012,09/08/2012"
      assert_results search, site1
    end

  end

  context "filter by date field range format dd/mm/yyyy" do
    let!(:creation) { layer.date_fields.make! code: 'creation', config: {'format' => 'dd_mm_yyyy'} }

    let!(:site1) { collection.sites.make! :name => 'b', properties: { creation.es_code =>"2012-09-07T00:00:00Z" }}
    let!(:site2) { collection.sites.make! :name => 'a', properties: { creation.es_code =>"2013-09-07T00:00:00Z" }}


    it "should search by range" do
      search = collection.new_search
      search.where creation.es_code => "=06/09/2012,08/09/2012"
      assert_results search, site1
    end

    it "searches by date with @code" do
      search = collection.new_search
      search.use_codes_instead_of_es_codes
      search.where creation.code => "=06/09/2012,08/09/2012"
      assert_results search, site1
    end

  end

  context 'filter by hierarchy' do
    let!(:unit) { layer.hierarchy_fields.make! code: 'unit', 'config' => {'hierarchy' => [{'id' => 1, 'name' => 'Buenos Aires', 'sub' => [{ 'id' => 2, 'name' => 'Vicente Lopez'}]}, {'id' => 3, 'name' => 'Formosa'}]} }
    let!(:first_name) { layer.text_fields.make! code: 'first_name'}

    let!(:site1) { collection.sites.make! properties:
      { first_name.es_code => "At Buenos Aires", unit.es_code => 1 }  }
    let!(:site2) { collection.sites.make! properties:
      { first_name.es_code => "At Vicente Lopez", unit.es_code => 2 } }
    let!(:site3) { collection.sites.make! properties:
      { first_name.es_code => "At Vicente Lopez 2", unit.es_code => 2 } }
    let!(:site4) { collection.sites.make! properties:
      { first_name.es_code => "At Formosa", unit.es_code => 3 } }
    let!(:site5) { collection.sites.make! properties:
      { first_name.es_code => "Nowhere" }  }

    it 'should filter sites inside some specified item by id' do
      search = collection.new_search
      search.where unit.es_code => { under: 1 }
      assert_results search, site1, site2, site3
    end

    it 'should filter sites inside some specified item by id again' do
      search = collection.new_search
      search.where unit.es_code => { under: 3 }
      assert_results search, site4
    end

    it 'should filter sites inside some specified item by name' do
      search = collection.new_search
      search.use_codes_instead_of_es_codes
      search.where unit.code => { under: 'Buenos Aires' }
      assert_results search, site1, site2, site3
    end

    it "searches by hierarchy with @code" do
      search = collection.new_search
      search.use_codes_instead_of_es_codes
      search.where unit.code => ['Buenos Aires']
      assert_results search, site1
    end

    it "searches by multiple hierarchy with @code" do
      search = collection.new_search
      search.use_codes_instead_of_es_codes
      search.where unit.code => ['Buenos Aires', 'Vicente Lopez']
      assert_results search, site1, site2, site3
    end

    it "searches by multiple hierarchy with @es_code" do
      search = collection.new_search
      search.where unit.es_code => [1, 2]
      assert_results search, site1, site2, site3
    end
  end

  context 'filter by yes_no' do
    let!(:cool) { layer.yes_no_fields.make! code: 'cool'}

    let!(:site1) { collection.sites.make! properties: { cool.es_code => true } }
    let!(:site2) { collection.sites.make! properties: { cool.es_code => false } }

    it "should filter by 'yes'" do
      search = collection.new_search
      search.where cool.es_code => 'yes'
      assert_results search, site1
    end

    it "should filter by 'no'" do
      search = collection.new_search
      search.where cool.es_code => 'no'
      assert_results search, site2
    end

    it "filter by no should get nil values" do
      site3 = collection.sites.make! properties: {}
      search = collection.new_search
      search.where cool.es_code => 'no'
      assert_results search, site2, site3
    end
  end

  context 'hierarchy parameter for select_kind and hierarchy fields' do
    let!(:select_one) { layer.select_one_fields.make! :code => 'select_one', :config => {'options' => [{'id' => 1, 'code' => 'one', 'label' => 'One'}, {'id' => 2, 'code' => 'two', 'label' => 'Two'}]} }
    let!(:select_many) { layer.select_many_fields.make! :code => 'select_many', :config => {'options' => [{'id' => 1, 'code' => 'one', 'label' => 'One'}, {'id' => 2, 'code' => 'two', 'label' => 'Two'}]} }
    config_hierarchy = [{ id: '60', name: 'Dad', sub: [{id: '100', name: 'Son'}, {id: '101', name: 'Bro'}]}]
    let!(:hierarchy) { layer.hierarchy_fields.make! :code => 'hierarchy', config: { hierarchy: config_hierarchy }.with_indifferent_access }

    let!(:site1) { collection.sites.make! properties:
     { select_one.es_code => "1", select_many.es_code => [1, 2], hierarchy.es_code => '100'}  }
    let!(:site2) { collection.sites.make! properties:
     { select_many.es_code => [2]} }
    let!(:site3) { collection.sites.make! properties:
     { select_one.es_code => "1", hierarchy.es_code  => '60'} }

    it "filters select one field" do
     search = collection.new_search
     search.hierarchy(select_one.es_code, "1")
     assert_results search, site1, site3
    end

    it "filter select many field" do
      search = collection.new_search
      search.hierarchy(select_many.es_code, "2")
      assert_results search, site1, site2
    end

    it "filter select many field with no value" do
      search = collection.new_search
      search.hierarchy(select_many.es_code, nil)
      assert_results search, site3
    end

    it "filter select one field with no value" do
      search = collection.new_search
      search.hierarchy(select_one.es_code, nil)
      assert_results search, site2
    end

    it "filter hierarchy field" do
      search = collection.new_search
      search.hierarchy(hierarchy.es_code, "60")
      assert_results search, site3
    end

    it "filter hierarchy field with no value" do
      search = collection.new_search
      search.hierarchy(hierarchy.es_code, nil)
      assert_results search, site2
    end
  end

  context "numeric" do
    let!(:layer) { collection.layers.make! }
    let!(:temperature) { layer.numeric_fields.make! :code => 'temp', config: {allows_decimals: "true"} }

    let!(:site1) { collection.sites.make! properties: { temperature.es_code => 45.6 } }

    it "finds by decimal number property and doesn't find" do
      assert_results collection.new_search.where(temperature.es_code => 45.123)
    end

    it "finds by decimal number property and finds" do
      assert_results collection.new_search.where(temperature.es_code => 45.6), site1
    end

    it "finds by decimal does not equal value" do
      assert_results collection.new_search.not_eq(temperature, 45.6)
      assert_results collection.new_search.not_eq(temperature, 45.7), site1
    end
  end

  def assert_results(search, *sites)
    expect(search.results.map{|r| r['_id'].to_i}).to match_array(sites.map(&:id))
  end
end
