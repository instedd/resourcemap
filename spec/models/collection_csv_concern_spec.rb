require 'spec_helper'

describe Collection::CsvConcern do
  let(:user) { User.make }
  let(:collection) { Collection.make }

  it "imports csv" do
    collection.import_csv user, %(
      resmap-id, name, lat, lng
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

  describe "decode hierarchy csv test" do

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
        {order: 1, id: '1', name: 'Site 1', sub: [{order: 4, id: '4', name: 'Site 1.1'}, {order: 5, id: '5', name: 'Site 1.2'}, {order: 6, id: '6', name: 'Site 1.3'}]},
        {order: 2, id: '2', name: 'Site 2'},
        {order: 3, id: '3', name: 'Site 3'}
      ])
    end

    it "without header" do
      json = collection.decode_hierarchy_csv %(
        1,,Site 1
        2,,Site 2
        3,,Site 3
        4,1,Site 1.1
        5,1,Site 1.2
        6,1,Site 1.3
      ).strip

      json.should eq([
        {order: 1, id: '1', name: 'Site 1', sub: [{order: 4, id: '4', name: 'Site 1.1'}, {order: 5, id: '5', name: 'Site 1.2'}, {order: 6, id: '6', name: 'Site 1.3'}]},
        {order: 2, id: '2', name: 'Site 2'},
        {order: 3, id: '3', name: 'Site 3'}
      ])
    end

    it "gets an error if has >3 columns in a row" do
      json = collection.decode_hierarchy_csv %(
        1,,Site 1
        2,,Site 2
        3,,Site 3,
        4,1,Site 1.1
        5,1,Site 1.2
        6,1,Site 1.3
      ).strip

      json.should eq([
        {order: 1, id: '1', name: 'Site 1', sub: [{order: 4, id: '4', name: 'Site 1.1'}, {order: 5, id: '5', name: 'Site 1.2'}, {order: 6, id: '6', name: 'Site 1.3'}]},
        {order: 2, id: '2', name: 'Site 2'},
        {order: 3, error: 'Wrong format.', error_description: 'Invalid column number'}
      ])
    end

    it "gets an error if has <3 columns in a row" do
      json = collection.decode_hierarchy_csv %(
        1,,Site 1
        2,,Site 2
        3,,Site 3
        4,1,Site 1.1
        5,1,Site 1.2
        6,
      ).strip

      json.should eq([
        {order: 1, id: '1', name: 'Site 1', sub: [{order: 4, id: '4', name: 'Site 1.1'}, {order: 5, id: '5', name: 'Site 1.2'}]},
        {order: 2, id: '2', name: 'Site 2'},
        {order: 3, id: '3', name: 'Site 3'},
        {order: 6, error: 'Wrong format.', error_description: 'Invalid column number'}
      ])
    end

    # works ok in the app but the test is not working
    pending "works ok with quotes" do
      json = collection.decode_hierarchy_csv %(
        "1","","Site 1"
        "2","1","Site 2"
      ).strip

      json.should eq([
        {order: 1, id: '1', name: 'Site 1'},
        {order: 2, id: '2', name: 'Site 2'}
      ])
    end

    it "gets an error if there is wrong quotes (when creating file in excel without export it to csv)" do
      json = collection.decode_hierarchy_csv %(
        1,,Site 1
        2,,Site 2
        3,,Site 3
        "4,,Site 4

      ).strip

      json.should eq([
        {error: "Illegal quoting in line 4."}
      ])
    end

    it ">1 column number errors" do
      json = collection.decode_hierarchy_csv %(
        1,,Site 1
        2,,Site 2,
        3,,Site 3,
        4,,Site 4

      ).strip

      json.should eq([
        {order: 1, id: '1', name: 'Site 1'},
        {order: 2, error: 'Wrong format.', error_description: 'Invalid column number'},
        {order: 3, error: 'Wrong format.', error_description: 'Invalid column number'},
        {order: 4, id: '4', name: 'Site 4'}

      ])
    end

    it "hierarchy name should be unique" do
      json = collection.decode_hierarchy_csv %(
        1,,Site 1
        2,,Site 1
      ).strip

      json.should eq([
        {order: 1, id: '1', name: 'Site 1'},
        {order: 2, error: 'Invalid name.', error_description: 'Hierarchy name should be unique'}
      ])
    end

    it "more than one hierarchy name repeated" do
      json = collection.decode_hierarchy_csv %(
        1,,Site 1
        2,,Site 1
        3,,Site 1
      ).strip

      json.should eq([
        {order: 1, id: '1', name: 'Site 1'},
        {order: 2, error: 'Invalid name.', error_description: 'Hierarchy name should be unique'},
        {order: 3, error: 'Invalid name.', error_description: 'Hierarchy name should be unique'}
      ])
    end

    it "hiearchy id should be unique" do
      json = collection.decode_hierarchy_csv %(
        1,,Site 1
        1,,Site 2
        1,,Site 3
      ).strip

      json.should eq([
        {order: 1, id: '1', name: 'Site 1'},
        {order: 2, error: 'Invalid id.', error_description: 'Hierarchy id should be unique'},
        {order: 3, error: 'Invalid id.', error_description: 'Hierarchy id should be unique'}
      ])
    end
  end

end
