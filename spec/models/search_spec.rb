require 'spec_helper'

describe Search do
  let!(:collection) { Collection.make }
  let!(:layer) { collection.layers.make }

  context "search by property" do
    let!(:beds) { layer.fields.make code: 'beds', kind: 'numeric' }
    let!(:tables) { layer.fields.make code: 'tables', kind: 'numeric' }
    let!(:first_name) { layer.fields.make code: 'first_name', kind: 'text' }
    let!(:country) { layer.fields.make code: 'country', kind: 'text' }


    let!(:site1) { collection.sites.make properties:
      {beds.es_code => 5, tables.es_code => 1, first_name.es_code => "peterin panini", country.es_code => "argentina"} }
    let!(:site2) { collection.sites.make properties:
      {beds.es_code => 10, tables.es_code => 2, first_name.es_code => "peter pan", country.es_code => "albania"}  }
    let!(:site3) { collection.sites.make properties:
      {beds.es_code => 20, tables.es_code => 3, first_name.es_code => "Alice Cooper", country.es_code => "argelia"}  }
    let!(:site4) { collection.sites.make properties:
      {beds.es_code => 10, tables.es_code => 4, first_name.es_code => "John Doyle", country.es_code => "south arabia"}  }

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

    it "searches by equality of two properties" do
      search = collection.new_search
      search.where beds.es_code => 10, tables.es_code => 2
      assert_results search, site2
    end

    it "searches by equality of two properties but doesn't find" do
      search = collection.new_search
      search.where beds.es_code => 10, tables.es_code => 1
      search.results.length.should eq(0)
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


    context "full text search" do
      let!(:population_source) { layer.fields.make :code => 'population_source', :kind => 'text' }

      it "searches by equality with text" do
        a_site = collection.sites.make :properties => {population_source.es_code => "National Census"}
        search = collection.new_search
        search.where population_source.es_code => "National Census"
        assert_results search, a_site
      end

      it "searches by equality with text doesn't confuse name" do
        a_site = collection.sites.make :name => "Census", :properties => {population_source.es_code => "National"}
        search = collection.new_search
        search.where population_source.es_code => "National Census"
        search.results.length.should eq(0)
      end
    end

    it "searches with lt" do
      search = collection.new_search
      search.lt beds.es_code, 8
      assert_results search, site1
    end

    it "searches with lt with code" do
      search = collection.new_search
      search.use_codes_instead_of_es_codes
      search.lt 'beds', 8
      assert_results search, site1
    end

    it "searches with lte" do
      search = collection.new_search
      search.lte beds.es_code, 10
      assert_results search, site1, site2, site4
    end

    it "searches with gt" do
      search = collection.new_search
      search.gt beds.es_code, 18
      assert_results search, site3
    end

    it "searches with gte" do
      search = collection.new_search
      search.gte beds.es_code, 10
      assert_results search, site2, site3, site4
    end

    it "searches with combined properties" do
      search = collection.new_search
      search.lt beds.es_code, 11
      search.gte tables.es_code, 4
      assert_results search, site4
    end

    it "searches with ops" do
      search = collection.new_search
      search.op beds.es_code, '<', 8
      search.op tables.es_code, '>=', 1
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
        lambda { search.where '0' => 10 }.should raise_error(RuntimeError, "Unknown field: 0")
      end
    end
  end

  context "find by id" do
    let!(:site1) { collection.sites.make }
    let!(:site2) { collection.sites.make }

    it "finds by id" do
      assert_results collection.new_search.id(site1.id), site1
    end
  end

  context "pagination" do
    it "paginates by 50 results by default" do
      Search.page_size.should eq(50)
    end

    context "with another page size" do
      before(:each) do
        @original_page_size = Search.page_size
        Search.page_size = 2
      end

      after(:each) do
        Search.page_size = @original_page_size
      end

      it "gets first page" do
        sites = 3.times.map { collection.sites.make }
        sites.sort! { |s1, s2| s1.name <=> s2.name }
        assert_results collection.new_search, sites[0], sites[1]
      end

      it "gets second page" do
        sites = 3.times.map { collection.sites.make }
        sites.sort! { |s1, s2| s1.name <=> s2.name }
        assert_results collection.new_search.page(2), sites[2]
      end
    end
  end

  context "after" do
    before(:each) do
      @site1 = collection.sites.make :updated_at => (Time.now - 3.days)
      @site2 = collection.sites.make :updated_at => (Time.now - 2.days)
      @site3 = collection.sites.make :updated_at => (Time.now - 1.days)
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
    let!(:layer) { collection.layers.make }
    let!(:prop) { layer.fields.make :kind => 'select_one', :code => 'prop', :config => {'options' => [{'id' => 1, 'code' => 'foo', 'label' => 'A glass of water'}, {'id' => 2, 'code' => 'bar', 'label' => 'A bottle of wine'}, {'id' => 3, 'code' => 'baz', 'label' => 'COCO'}]} }
    let!(:beds) { layer.fields.make :kind => 'numeric', :code => 'beds' }
    let!(:site1) { collection.sites.make :name => "Argentina", :properties => {beds.es_code => 8, prop.es_code => 1} }
    let!(:site2) { collection.sites.make :name => "Buenos Aires", :properties => {beds.es_code => 10, prop.es_code => 2} }
    let!(:site3) { collection.sites.make :name => "Cordoba bar Buenos", :properties => {beds.es_code => 20, prop.es_code => 3} }

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
      assert_results collection.new_search.where(prop.es_code => "A glass of water"), site1
    end

    it "doesn't give false positives" do
      assert_results collection.new_search.full_text_search("wine"), site2
    end

    it "searches whole phrase, not part of it" do
      assert_results collection.new_search.full_text_search("Buenos Aires"), site2
    end

    pending "searches by name property" do
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
  end

  context "geo" do
    let!(:site1) { collection.sites.make lat: 10, lng: 20}
    let!(:site2) { collection.sites.make lat: 15, lng: 25}
    let!(:site3) { collection.sites.make lat: 40, lng: 60}

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
      assert_results collection.new_search.radius(12.5, 22.5, 600000), site1, site2
    end

    it "searches by numeric radius on single site" do
      assert_results collection.new_search.radius(10, 20, 1), site1
    end
  end

  context "results format" do
    let!(:text) { layer.fields.make :code => 'text', :kind => 'text' }
    let!(:numeric) { layer.fields.make :code => 'numeric', :kind => 'numeric' }
    let!(:select_one) { layer.fields.make :code => 'select_one', :kind => 'select_one', :config => {'options' => [{'id' => 1, 'code' => 'one', 'label' => 'One'}, {'id' => 2, 'code' => 'two', 'label' => 'Two'}]} }
    let!(:select_many) { layer.fields.make :code => 'select_many', :kind => 'select_many', :config => {'options' => [{'id' => 1, 'code' => 'one', 'label' => 'One'}, {'id' => 2, 'code' => 'two', 'label' => 'Two'}]} }

    let!(:site1) { collection.sites.make :lat => 1, :lng => 2, :properties => {text.es_code => 'foo', numeric.es_code => 1, select_one.es_code => 1, select_many.es_code => [1, 2]} }

    it "gets results" do
      result = collection.new_search.results[0]
      result['_source']['properties'][text.es_code].should eq('foo')
      result['_source']['properties'][numeric.es_code].should eq(1)
      result['_source']['properties'][select_one.es_code].should eq(1)
      result['_source']['properties'][select_many.es_code].should eq([1, 2])
    end

    it "gets api results" do
      result = collection.new_search.api_results[0]
      result['_source']['properties'][text.code].should eq('foo')
      result['_source']['properties'][numeric.code].should eq(1)
      result['_source']['properties'][select_one.code].should eq('one')
      result['_source']['properties'][select_many.code].should eq(['one', 'two'])
    end

    it "gets ui results" do
      result = collection.new_search.ui_results[0]
      result['_source']['lat'].should eq(1)
      result['_source']['lng'].should eq(2)
    end
  end

  context "sort" do
    let!(:numeric) { layer.fields.make :code => 'numeric', :kind => 'numeric' }

    let!(:site1) { collection.sites.make :name => 'Brian Adams', :properties => {numeric.es_code => 2} }
    let!(:site2) { collection.sites.make :name => 'Esther Goris', :properties => {numeric.es_code => 1} }

    let!(:search) { collection.new_search.use_codes_instead_of_es_codes }

    it "sorts on name asc by default" do
      result = search.results
      result.map { |x| x['_id'].to_i } .should eq([site1.id, site2.id])
    end

    it "sorts by field asc" do
      result = search.sort(numeric.code).results
      result.map { |x| x['_id'].to_i } .should eq([site2.id, site1.id])
    end

    it "sorts by field desc" do
      result = search.sort(numeric.code, false).results
      result.map { |x| x['_id'].to_i } .should eq([site1.id, site2.id])
    end

    it "sorts by name asc" do
      result = search.sort('name').results
      result.map { |x| x['_id'].to_i } .should eq([site1.id, site2.id])
    end

    it "sorts by name desc" do
      result = search.sort('name', false).results
      result.map { |x| x['_id'].to_i } .should eq([site2.id, site1.id])
    end
  end

  context "location missing" do
    let!(:site1) { collection.sites.make :name => 'b', :lat => "", :lng => ""  }
    let!(:site2) { collection.sites.make :name => 'a' }

    it "should filter sites without location" do
      result = collection.new_search.location_missing.results
      result.map { |x| x['_id'].to_i } .should eq([site1.id])
    end

  end

  context "filter by date field range" do
    let!(:creation) { layer.fields.make code: 'creation', kind: 'date' }
    let!(:inaguration) { layer.fields.make code: 'inaguration', kind: 'date' }

    let!(:site1) { collection.sites.make :name => 'b', properties: { creation.es_code =>"2012-09-07T03:00:00.000Z", inaguration.es_code =>"2012-09-23T03:00:00.000Z"} }
    let!(:site2) { collection.sites.make :name => 'a', properties: { creation.es_code =>"2013-09-07T03:00:00.000Z", inaguration.es_code =>"2012-09-23T03:00:00.000Z"} }

    it "should parse date from" do
      search = collection.new_search
      parameter = "12/12/2012,1/1/2013"
      field = search.send(:parse_date_from, parameter)
      field.should eq("12/12/2012")
    end

    it "should parse date to" do
      search = collection.new_search
      parameter = "12/12/2012,1/1/2013"
      field = search.send(:parse_date_to, parameter)
      field.should eq("1/1/2013")
    end

    it "should search by range" do
      search = collection.new_search
      search.where creation.es_code => "=09/06/2012,09/08/2012"
      assert_results search, site1
    end

    it "should serch by especific date" do
      search = collection.new_search
      search.where inaguration.es_code => "=09/23/2012,09/23/2012"
      assert_results search, site1, site2
    end

  end

  def assert_results(search, *sites)
    search.results.map{|r| r['_id'].to_i}.should =~ sites.map(&:id)
  end
end
