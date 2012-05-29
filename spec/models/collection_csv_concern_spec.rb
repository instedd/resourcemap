require 'spec_helper'

describe Collection::CsvConcern do
  let(:user) { User.make }
  let(:collection) { Collection.make }

  it "imports csv" do
    collection.import_csv user, %(
      id, name, lat, lng
      1, Site 1, 10, 20
      2, Site 2, 30, 40
    ).strip

    collection.reload
    roots = collection.sites.all
    roots.length.should eq(2)

    roots[0].name.should eq('Site 1')
    roots[0].lat.to_f.should eq(10.0)
    roots[0].lng.to_f.should eq(20.0)

    roots[1].name.should eq('Site 2')
    roots[1].lat.to_f.should eq(30.0)
    roots[1].lng.to_f.should eq(40.0)
  end

  it "decodes hierarchy csv" do
    json = collection.decode_hierarchy_csv %(
      ID, ParentID, ItemName
      1,,Site 1
      2,,Site 2
      3,,Site 3
      4,1,Site 1.1
      5,1,Site 1.2
      6,1,Site 1.3
    ).strip

    json.should eq([
      {id: '1', name: 'Site 1', sub: [{id: '4', name: 'Site 1.1'}, {id: '5', name: 'Site 1.2'}, {id: '6', name: 'Site 1.3'}]},
      {id: '2', name: 'Site 2'},
      {id: '3', name: 'Site 3'}
    ])
  end
end
