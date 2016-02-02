require 'spec_helper'

describe Collection::CsvConcern, :type => :model do
  let(:user) { User.make }
  let(:collection) { user.create_collection Collection.make }
  let(:layer) { collection.layers.make }

  it "should print date as MM/DD/YYYY" do
    date = layer.date_fields.make :code => 'date'
    site = collection.sites.make :properties => {date.es_code => '1985-10-19T00:00:00Z'}

    csv =  CSV.parse collection.to_csv(collection.new_search(:current_user_id => user.id).unlimited.api_results, user)

    expect(csv[1][4]).to eq('10/19/1985')
  end

  it "should download hiearchy value as Id" do
    config_hierarchy = [{ id: '60', name: 'Dad', sub: [{id: '100', name: 'Son'}, {id: '101', name: 'Bro'}]}]
    hierarchy_field = layer.hierarchy_fields.make :code => 'hierarchy', config: { hierarchy: config_hierarchy }.with_indifferent_access

    site = collection.sites.make :properties => {hierarchy_field.es_code => '100'}

    csv =  CSV.parse collection.to_csv(collection.new_search(:current_user_id => user.id).unlimited.api_results, user)
    expect(csv[1][4]).to eq('100')
  end


  it "should add a column for each level of the hierarchy in the CSV" do
    config_hierarchy = [{ id: '60', name: 'Dad', sub: [{id: '100', name: 'Son'}, {id: '101', name: 'Bro'}]}]
    hierarchy_field = layer.hierarchy_fields.make :code => 'hierarchy', config: { hierarchy: config_hierarchy }.with_indifferent_access

    site = collection.sites.make :properties => {hierarchy_field.es_code => '100'}
    csv =  CSV.parse collection.to_csv(collection.new_search(:current_user_id => user.id).unlimited.api_results, user)

    expect(csv.first).to eq(["resmap-id", "name", "lat", "long", "hierarchy", "hierarchy-1", "hierarchy-2", "last updated"])
    expect(csv[1][4]).to eq('100')
    expect(csv[1][5]).to eq('Dad')
    expect(csv[1][6]).to eq('Son')
  end

  it "should add empty columns for the values that are not leafs" do
    config_hierarchy = [{ id: '60', name: 'Dad', sub: [{id: '100', name: 'Son'}, {id: '101', name: 'Bro'}]}]
    hierarchy_field = layer.hierarchy_fields.make :code => 'hierarchy', config: { hierarchy: config_hierarchy }.with_indifferent_access

    site = collection.sites.make :properties => {hierarchy_field.es_code => '60'}
    csv =  CSV.parse collection.to_csv(collection.new_search(:current_user_id => user.id).unlimited.api_results, user)

    expect(csv.first).to eq(["resmap-id", "name", "lat", "long", "hierarchy", "hierarchy-1", "hierarchy-2", "last updated"])
    expect(csv[1][4]).to eq('60')
    expect(csv[1][5]).to eq('Dad')
    expect(csv[1][6]).to eq('')
  end

  context 'human flag' do
    context "turned on" do
      it "should send select one names" do
        select_one = layer.select_one_fields.make :code => 'select_one',  :config => {'next_id' => 3, 'options' => [{'id' => 1, 'code' => 'one', 'label' => 'One'}, {'id' => 2, 'code' => 'two', 'label' => 'Two'}]}
        site = collection.sites.make :properties => {select_one.es_code => 1}

        csv =  CSV.parse collection.to_csv(collection.new_search(:current_user_id => user.id).unlimited.api_results, user, nil, {human: true})

        expect(csv[1][4]).to eq('One')
      end

      it "should send select many names" do
        select_many = layer.select_many_fields.make :code => 'select_one',  :config => {'next_id' => 3, 'options' => [{'id' => 1, 'code' => 'one', 'label' => 'One'}, {'id' => 2, 'code' => 'two', 'label' => 'Two'}]}
        site = collection.sites.make :properties => {select_many.es_code => [1,2]}

        csv =  CSV.parse collection.to_csv(collection.new_search(:current_user_id => user.id).unlimited.api_results, user, nil, {human: true})

        expect(csv[1][4]).to eq('One, Two')
      end

      it "should send hierarchy names" do
        config_hierarchy = [{ id: '60', name: 'Dad', sub: [{id: '100', name: 'Son'}, {id: '101', name: 'Bro'}]}]
        hierarchy_field = layer.hierarchy_fields.make :code => 'hierarchy', config: { hierarchy: config_hierarchy }.with_indifferent_access

        site = collection.sites.make :properties => {hierarchy_field.es_code => '100'}
        csv =  CSV.parse collection.to_csv(collection.new_search(:current_user_id => user.id).unlimited.api_results, user, nil, {human: true})

        expect(csv.first).to eq(["resmap-id", "name", "lat", "long", "hierarchy", "hierarchy-1", "hierarchy-2", "last updated"])
        expect(csv[1][4]).to eq('Dad - Son')
        expect(csv[1][5]).to eq('Dad')
        expect(csv[1][6]).to eq('Son')
      end

    end

    context "turned off" do
      it "should send select one codes" do
        select_one = layer.select_one_fields.make :code => 'select_one',  :config => {'next_id' => 3, 'options' => [{'id' => 1, 'code' => 'one', 'label' => 'One'}, {'id' => 2, 'code' => 'two', 'label' => 'Two'}]}
        site = collection.sites.make :properties => {select_one.es_code => 1}

        csv =  CSV.parse collection.to_csv(collection.new_search(:current_user_id => user.id).unlimited.api_results, user)

        expect(csv[1][4]).to eq('one')
      end

      it "should send select many codes" do
        select_many = layer.select_many_fields.make :code => 'select_one',  :config => {'next_id' => 3, 'options' => [{'id' => 1, 'code' => 'one', 'label' => 'One'}, {'id' => 2, 'code' => 'two', 'label' => 'Two'}]}
        site = collection.sites.make :properties => {select_many.es_code => [1,2]}

        csv =  CSV.parse collection.to_csv(collection.new_search(:current_user_id => user.id).unlimited.api_results, user)

        expect(csv[1][4]).to eq('one, two')
      end
    end
  end


  it "should add a column for each level of the hierarchy in the CSV" do
    config_hierarchy = [{ id: '60', name: 'Dad', sub: [{id: '100', name: 'Son'}, {id: '101', name: 'Bro'}]}]
    hierarchy_field = layer.hierarchy_fields.make :code => 'hierarchy', config: { hierarchy: config_hierarchy }.with_indifferent_access

    site = collection.sites.make :properties => {hierarchy_field.es_code => '100'}
    csv =  CSV.parse collection.to_csv(collection.new_search(:current_user_id => user.id).unlimited.api_results, user)

    expect(csv.first).to eq(["resmap-id", "name", "lat", "long", "hierarchy", "hierarchy-1", "hierarchy-2", "last updated"])
    expect(csv[1][4]).to eq('100')
    expect(csv[1][5]).to eq('Dad')
    expect(csv[1][6]).to eq('Son')
  end

  it "should add empty columns for the values that are not leafs" do
    config_hierarchy = [{ id: '60', name: 'Dad', sub: [{id: '100', name: 'Son'}, {id: '101', name: 'Bro'}]}]
    hierarchy_field = layer.hierarchy_fields.make :code => 'hierarchy', config: { hierarchy: config_hierarchy }.with_indifferent_access

    site = collection.sites.make :properties => {hierarchy_field.es_code => '60'}
    csv =  CSV.parse collection.to_csv(collection.new_search(:current_user_id => user.id).unlimited.api_results, user)

    expect(csv.first).to eq(["resmap-id", "name", "lat", "long", "hierarchy", "hierarchy-1", "hierarchy-2", "last updated"])
    expect(csv[1][4]).to eq('60')
    expect(csv[1][5]).to eq('Dad')
    expect(csv[1][6]).to eq('')
  end

  describe "generate sample csv" do

    it "should include only visible fields for the user" do
      user2 = User.make

      layer_visible = collection.layers.make
      layer_invisible = collection.layers.make
      layer_writable = collection.layers.make

      date_visible = layer_visible.date_fields.make :code => 'date_visible'
      date_invisible = layer_invisible.date_fields.make :code => 'date_invisible'
      date_writable = layer_writable.date_fields.make :code => 'date_writable'

      membership = collection.memberships.make :user => user2
      membership.activity_user = user
      membership.admin = false
      membership.set_layer_access :verb => :read, :access => true, :layer_id => layer_visible.id
      membership.set_layer_access :verb => :read, :access => false, :layer_id => layer_invisible.id
      membership.set_layer_access :verb => :write, :access => true, :layer_id => layer_writable.id
      membership.save!

      csv = CSV.parse(collection.sample_csv user2)

      expect(csv[0]).to include('date_writable')
      expect(csv[0]).not_to include('date_visible')
      expect(csv[0]).not_to include('date_invisible')
      expect(csv[1].length).to be(4)
    end
  end

  describe "decode hierarchy csv test" do

    after(:each) do
      File.delete("hierarchy_csv_file.csv")
    end

    it "gets parents right even with blank lines at the end" do
      CSV.open("hierarchy_csv_file.csv", "w") do |csv|
        csv << ['ID', 'ParentID', 'ItemName']
        csv << ['1','','Dispensary']
        csv << ['2','','Health Centre']
        csv << ['101','1','Lab Dispensary']
        csv << ['102','1','Clinical Dispensary']
        csv << ['201','2','Health Centre Type 1']
        csv << ['202','2','Health Centre Type 2']
        csv << ['', '', '', '']
      end

      json = collection.decode_hierarchy_csv_file "hierarchy_csv_file.csv"
      expect(json).to eq([
        {order: 1, id: '1', name: 'Dispensary', sub: [{order: 3, id: '101', name: 'Lab Dispensary'}, {order: 4, id: '102', name: 'Clinical Dispensary'}]},
        {order: 2, id: '2', name: 'Health Centre', sub: [{order: 5, id: '201', name: 'Health Centre Type 1'}, {order: 6, id: '202', name: 'Health Centre Type 2'}]},
      ])
    end

    it "decodes hierarchy csv" do
      CSV.open("hierarchy_csv_file.csv", "w") do |csv|
        csv << ['ID', 'ParentID', 'ItemName']
        csv << ['1','','Location 1']
        csv << ['2','','Location 2']
        csv << ['3','','Location 3']
        csv << ['4','1','Location 1.1']
        csv << ['5','1','Location 1.2']
        csv << ['6','1','Location 1.3']
      end

      json = collection.decode_hierarchy_csv_file "hierarchy_csv_file.csv"
      expect(json).to eq([
        {order: 1, id: '1', name: 'Location 1', sub: [{order: 4, id: '4', name: 'Location 1.1'}, {order: 5, id: '5', name: 'Location 1.2'}, {order: 6, id: '6', name: 'Location 1.3'}]},
        {order: 2, id: '2', name: 'Location 2'},
        {order: 3, id: '3', name: 'Location 3'}
      ])
    end

    it "without header" do
      CSV.open("hierarchy_csv_file.csv", "w") do |csv|
        csv << ['1','','Location 1']
        csv << ['2','','Location 2']
        csv << ['3','','Location 3']
        csv << ['4','1','Location 1.1']
        csv << ['5','1','Location 1.2']
        csv << ['6','1','Location 1.3']
      end

      json = collection.decode_hierarchy_csv_file "hierarchy_csv_file.csv"
      expect(json).to eq([
        {order: 1, id: '1', name: 'Location 1', sub: [{order: 4, id: '4', name: 'Location 1.1'}, {order: 5, id: '5', name: 'Location 1.2'}, {order: 6, id: '6', name: 'Location 1.3'}]},
        {order: 2, id: '2', name: 'Location 2'},
        {order: 3, id: '3', name: 'Location 3'}
      ])
    end

    it "gets an error if has >4 columns in a row" do
      CSV.open("hierarchy_csv_file.csv", "w") do |csv|
        csv << ['1','','Location 1']
        csv << ['2','','Location 2']
        csv << ['3','','Location 3','distict', '']
        csv << ['4','1','Location 1.1']
        csv << ['5','1','Location 1.2']
        csv << ['6','1','Location 1.3']
      end

      json = collection.decode_hierarchy_csv_file "hierarchy_csv_file.csv"
      expect(json).to eq([
        {order: 1, id: '1', name: 'Location 1', sub: [{order: 4, id: '4', name: 'Location 1.1'}, {order: 5, id: '5', name: 'Location 1.2'}, {order: 6, id: '6', name: 'Location 1.3'}]},
        {order: 2, id: '2', name: 'Location 2'},
        {order: 3, error: 'Wrong format.', error_description: 'Invalid column number'}
      ])
    end

    it "gets an error if has <3 columns in a row" do
      CSV.open("hierarchy_csv_file.csv", "w") do |csv|
        csv << ['1','','Location 1']
        csv << ['2','','Location 2']
        csv << ['3','','Location 3',]
        csv << ['4','1','Location 1.1']
        csv << ['5','1','Location 1.2']
        csv << ['6']
      end

      json = collection.decode_hierarchy_csv_file "hierarchy_csv_file.csv"
      expect(json).to eq([
        {order: 1, id: '1', name: 'Location 1', sub: [{order: 4, id: '4', name: 'Location 1.1'}, {order: 5, id: '5', name: 'Location 1.2'}]},
        {order: 2, id: '2', name: 'Location 2'},
        {order: 3, id: '3', name: 'Location 3'},
        {order: 6, error: 'Wrong format.', error_description: 'Invalid column number'}
      ])
    end

    it "works ok with quotes" do
      CSV.open("hierarchy_csv_file.csv", "w") do |csv|
        csv << ["1","","Location 1"]
        csv << ["2","","Location 2"]
      end

      json = collection.decode_hierarchy_csv_file "hierarchy_csv_file.csv"
      expect(json).to eq([
        {order: 1, id: '1', name: 'Location 1'},
        {order: 2, id: '2', name: 'Location 2'}
      ])
    end

    it "gets an error if the parent does not exists" do
      CSV.open("hierarchy_csv_file.csv", "w") do |csv|
        csv << ['ID', 'ParentID', 'ItemName']
        csv << ['1','','Dispensary']
        csv << ['2','','Health Centre']
        csv << ['101','10','Lab Dispensary']
      end

      json = collection.decode_hierarchy_csv_file "hierarchy_csv_file.csv"
      expect(json).to eq([
        {order: 1, id: '1', name: 'Dispensary', },
        {order: 2, id: '2', name: 'Health Centre'},
        {order: 3, error: 'Invalid parent value.', error_description: 'ParentID should match one of the Hierarchy ids'},
      ])
    end

    it ">1 column number errors" do

      CSV.open("hierarchy_csv_file.csv", "w") do |csv|
        csv << ['1','','Location 1']
        csv << ['2','','Location 2','district', '']
        csv << ['3','','Location 3','district', '']
        csv << ['4','','Location 4']
      end

      json = collection.decode_hierarchy_csv_file "hierarchy_csv_file.csv"
      expect(json).to eq([
        {order: 1, id: '1', name: 'Location 1'},
        {order: 2, error: 'Wrong format.', error_description: 'Invalid column number'},
        {order: 3, error: 'Wrong format.', error_description: 'Invalid column number'},
        {order: 4, id: '4', name: 'Location 4'}

      ])
    end

    it "hierarchy name should can be duplicated" do
      CSV.open("hierarchy_csv_file.csv", "w") do |csv|
        csv << ['1','','Location 1']
        csv << ['2','','Location 1']
      end

      json = collection.decode_hierarchy_csv_file "hierarchy_csv_file.csv"
      expect(json).to eq([
        {order: 1, id: '1', name: 'Location 1'},
        {order: 2, id: '2', name: 'Location 1'},
      ])
    end


    it "hiearchy id should be unique" do
      CSV.open("hierarchy_csv_file.csv", "w") do |csv|
        csv << ['1','','Location 1']
        csv << ['1','','Location 1']
        csv << ['1','','Location 1']
      end

      json = collection.decode_hierarchy_csv_file "hierarchy_csv_file.csv"
      expect(json).to eq([
        {order: 1, id: '1', name: 'Location 1'},
        {order: 2, error: 'Invalid id.', error_description: 'Hierarchy id should be unique'},
        {order: 3, error: 'Invalid id.', error_description: 'Hierarchy id should be unique'}
      ])
    end

    it "should store type" do
      CSV.open("hierarchy_csv_file.csv", "w") do |csv|
        csv << ["ID", "ParentID", "ItemName", "Type"]
        csv << ['1','','Location 1', "district"]
        csv << ['2','1','Location 1.2', "region"]
        csv << ['3','2','Location 1.2.3', 'ward']
      end

      json = collection.decode_hierarchy_csv_file "hierarchy_csv_file.csv"
      expect(json).to eq([
        {order: 1, id: '1', name: 'Location 1', type: "district", sub: [
          {order: 2, id: '2', name: 'Location 1.2', type: "region", sub: [
            {order: 3, id: '3', name: 'Location 1.2.3', type: "ward"}
          ]}
        ]}
      ])
    end
  end

  it "should generate error description form preprocessed hierarchy list" do
    hierarchy_csv = [
      {:order=>1, :error=>"Wrong format.", :error_description=>"Invalid column number"},
      {:order=>2, :id=>"2", :name=>"dad", :sub=>[{:order=>3, :id=>"3", :name=>"son"}]} ]

    res = collection.generate_error_description_list(hierarchy_csv)

    expect(res).to eq("Error: Wrong format. Invalid column number in line 1.")
  end

  it "should generate error description form invalid hierarchy list" do
    hierarchy_csv = [{:error=>"Illegal quoting in line 3."}]

    res = collection.generate_error_description_list(hierarchy_csv)

    expect(res).to eq("Error: Illegal quoting in line 3.")
  end

  it "should generate error description html form invalid hierarchy list with >1 errors" do
    hierarchy_csv = [
      {:order=>1, :error=>"Wrong format.", :error_description=>"Invalid column number"},
      {:order=>2, :error=>"Wrong format.", :error_description=>"Invalid column number"} ]


    res = collection.generate_error_description_list(hierarchy_csv)

    expect(res).to eq("Error: Wrong format. Invalid column number in line 1.<br/>Error: Wrong format. Invalid column number in line 2.")
  end

end
