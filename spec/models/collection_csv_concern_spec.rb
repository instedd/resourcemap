require 'spec_helper'

describe Collection::CsvConcern do
  let(:user) { User.make }
  let(:collection) { Collection.make }

  it "imports csv" do
    collection.import_csv user, %(
      id, type, name, lat, lng, parent, mode
      1, group, Group 1, 10, 20, , manual
      2, site, Site 1, 30, 40, 1,
    ).strip

    collection.reload
    roots = collection.root_sites.all
    roots.length.should eq(1)
    roots[0].name.should eq('Group 1')
    roots[0].lat.to_f.should eq(10.0)
    roots[0].lng.to_f.should eq(20.0)
    roots[0].location_mode.should eq('manual')

    subsites = roots[0].sites.all
    subsites.length.should eq(1)
    subsites[0].name.should eq('Site 1')
    subsites[0].lat.to_f.should eq(30.0)
    subsites[0].lng.to_f.should eq(40.0)
  end

  it "exports csv" do
    root = collection.sites.make :group => true, :location_mode => :manual
    site = collection.sites.make :parent_id => root.id

    collection.reload
    csv = collection.export_csv
    csv.strip.should eq(%(
Site ID,Type,Name,Lat,Lng,Parent ID,Mode
#{root.id},Group,#{root.name},#{root.lat},#{root.lng},,#{root.location_mode}
#{site.id},Site,#{site.name},#{site.lat},#{site.lng},#{root.id},
).strip)
  end


  it "exports csv template" do
    collection.csv_template.strip.should eq(%(
Site ID,Type,Name,Lat,Lng,Parent ID,Mode
1,Group,Group A,1.234,5.678,,none/manual/automatic
2,Site,Site A.1,2.345,6.789,1,
3,Group,Group B,3.456,4.567,,none/manual/automatic
4,Site,Site B.1,4.567,5.678,2,
    ).strip)
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
