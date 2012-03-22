require 'spec_helper'

describe Search do
  let!(:collection) { Collection.make }

  context "search by property" do
    let!(:site1) { collection.sites.make :properties => {'beds' => 5, 'tables' => 1} }
    let!(:site2) { collection.sites.make :properties => {'beds' => 10, 'tables' => 2} }
    let!(:site3) { collection.sites.make :properties => {'beds' => 20, 'tables' => 3} }

    it "searches by equality" do
      search = collection.new_search
      search.where beds: 10
      assert_results search, site2
    end

    it "searches by equality with at" do
      search = collection.new_search
      search.where '@beds' => 10
      assert_results search, site2
    end

    it "searches by equality of two properties" do
      search = collection.new_search
      search.where beds: 10, tables: 2
      assert_results search, site2
    end

    it "searches by equality of two properties but doesn't find" do
      search = collection.new_search
      search.where beds: 10, tables: 1
      search.results.length.should eq(0)
    end

    it "searches with lt" do
      search = collection.new_search
      search.lt :beds, 8
      assert_results search, site1
    end

    it "searches with lte" do
      search = collection.new_search
      search.lte :beds, 10
      assert_results search, site1, site2
    end

    it "searches with gt" do
      search = collection.new_search
      search.gt :beds, 18
      assert_results search, site3
    end

    it "searches with gte" do
      search = collection.new_search
      search.gte :beds, 10
      assert_results search, site2, site3
    end

    it "searches with combined properties" do
      search = collection.new_search
      search.lt :beds, 8
      search.gte :tables, 1
      assert_results search, site1
    end

    it "searches with ops" do
      search = collection.new_search
      search.op :beds, '<', 8
      search.op :tables, '>=', 1
      assert_results search, site1
    end

    context "where with op" do
      it "searches where with lt" do
        search = collection.new_search
        search.where beds: '< 8'
        assert_results search, site1
      end

      it "searches where with lte" do
        search = collection.new_search
        search.where beds: '<= 5'
        assert_results search, site1
      end

      it "searches where with gt" do
        search = collection.new_search
        search.where beds: '> 19'
        assert_results search, site3
      end

      it "searches where with gte" do
        search = collection.new_search
        search.where beds: '>= 20'
        assert_results search, site3
      end

      it "searches where with eq" do
        search = collection.new_search
        search.where beds: '= 10'
        assert_results search, site2
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
        assert_results collection.new_search, sites[0], sites[1]
      end

      it "gets second page" do
        sites = 3.times.map { collection.sites.make }
        assert_results collection.new_search.page(2), sites[2]
      end
    end
  end

  context "in group" do
    before(:each) do
      @parent1 = collection.sites.make :group => true
        @parent11 = collection.sites.make :parent_id => @parent1.id, :group => true
          @site111 = collection.sites.make :parent_id => @parent11.id
          @site112 = collection.sites.make :parent_id => @parent11.id
        @site11 = collection.sites.make :parent_id => @parent1.id
      @parent2 = collection.sites.make :group => true
        collection.sites.make :parent_id => @parent2.id
    end

    it "gets sites in root group" do
      search = collection.new_search.in_group(@parent1)
      assert_results search, @site111, @site112, @site11
    end

    it "gets sites in nested group" do
      search = collection.new_search.in_group(@parent11)
      assert_results search, @site111, @site112
    end

    it "gets sites in nested group with id" do
      search = collection.new_search.in_group(@parent11.id)
      assert_results search, @site111, @site112
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

  context "reserved keywords" do
    let!(:site1) { collection.sites.make :properties => {'type' => 'foo'} }
    let!(:site2) { collection.sites.make :properties => {'type' => 'bar'} }

    it "searches by type" do
      results = collection.new_search.where(type: 'foo').results
      results.length.should eq(1)
      results[0]['_id'].to_i.should eq(site1.id)
      results[0]['_source']['properties']['type'].should eq(site1.properties['type'])
    end
  end

  def assert_results(search, *sites)
    search.results.map{|r| r['_id'].to_i}.sort.should =~ sites.map(&:id)
  end
end