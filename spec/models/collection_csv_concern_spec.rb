require 'spec_helper'

describe Collection::CsvConcern do
  let(:collection) { Collection.make }

  it "imports csv" do
    collection.import_csv! %(
      id, name, lat, lng, parent, mode
      1, Group 1, 10, 20, , manual
      2, Site 1, 30, 40, 1,
    )

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
ID,Name,Lat,Lng,Parent ID,Mode
#{root.id},#{root.name},#{root.lat},#{root.lng},,#{root.location_mode}
#{site.id},#{site.name},#{site.lat},#{site.lng},#{root.id},
).strip)
  end
end
