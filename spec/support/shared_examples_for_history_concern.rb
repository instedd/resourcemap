shared_examples "it includes History::Concern" do
  it "should store history on creation" do
    model = described_class.make_unsaved
    model.histories.count.should == 0
    model.save!
    model.histories.count.should == 1
  end

  it "should store history on update" do
    model = described_class.make
    model.histories.count.should == 1
    model.name = "New name"
    model.save!
    model.name.should == "New name"
    model.histories.count.should == 2
    model.histories.last.name.should == "New name"
  end

  it "should set valid_to in history on update" do
    model = described_class.make
    model.name = "New name"
    model.save!
    model.histories.count.should == 2
    model.histories.first.valid_to.to_i.should eq(model.updated_at.to_i)
    model.histories.last.valid_to.should be_nil
  end

  it "should set valid_to in history before delete" do
    model = described_class.make
    model.histories.count.should == 1
    model.histories.last.valid_to.should be_nil

    stub_time '2020-01-01 10:00:00'

    model.destroy
    histories = model.histories.all
    described_class.find_all_by_id(model.id).count.should == 0
    histories.count.should == 1
    histories.last.valid_to.should eq(Time.now)
  end

  it "shouldn't get current history when destroyed" do
    model = described_class.make
    model.destroy
    model_history = model.current_history
    model_history.should be_nil
  end

  it "should get current history for new model" do
    model = described_class.make
    model_history = model.current_history
    model_history.should be
    assert_model_equals_history model, model_history
    model_history.valid_to.should be_nil
    model_history.valid_since.to_i.should eq(model.created_at.to_i)
  end

  it "should get current history for updated model" do
    stub_time '2010-01-01 09:00:00'
    model = described_class.make

    stub_time '2010-02-02 09:00:00'
    model.name = "new name"
    model.save!

    model_history = model.current_history
    model_history.should be
    model_history.valid_to.should be_nil
    assert_model_equals_history model, model_history
    model_history.valid_since.to_i.should eq(model.updated_at.to_i)
  end

  it "should not get new elements in history for date" do
    collection = Collection.make

    stub_time '2011-01-01 10:00:00'

    described_class.make name: '1 last year', collection_id: collection.id
    described_class.make name: '2 last year', collection_id: collection.id

    stub_time '2012-06-05 12:17:58'

    described_class.make name: '3 today', collection_id: collection.id
    described_class.make name: '4 today', collection_id: collection.id

    date = '2011-01-01 10:00:00'.to_time
    histories = collection.send("#{described_class}_histories".downcase).at_date(date)
    histories.count.should eq(2)
  end

  def assert_model_equals_history(model, history)
    model.attributes.keys.each do |key|
      model[key].should eq(history[key]) unless ['id', 'created_at', 'updated_at'].include? key
    end
    history[model.class.name.foreign_key].should eq(model.id)
  end
end
