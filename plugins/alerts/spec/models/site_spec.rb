require 'spec_helper'

describe Site do

  let!(:collection) { Collection.make selected_plugins: ['alerts'] }
  let!(:layer) { collection.layers.make }
  let!(:beds_field) { layer.fields.make code: 'beds', kind: 'numeric' }
  let!(:threshold) { collection.thresholds.make is_all_site: true,
    is_all_condition: true,
    conditions: [ {field: beds_field.es_code, op: :gt, value: '10'} ],
    icon: 'foo.png'
  }

  it "set alert in the index properties" do
    site = collection.sites.make :properties => {beds_field.es_code => 100 }

    search = Tire::Search::Search.new site.index_name
    results = search.perform.results
    results.length.should eq(1)
    results[0]["_source"]["alert"].should eq(true)
    results[0]["_source"]["icon"].should eq('foo.png')
  end
end