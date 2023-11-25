shared_examples "it includes History::Concern" do

  it "should store history on creation" do
    model = history_concern_class.make_unsaved
    expect(model.histories.count).to eq(0)
    model.save!
    expect(model.histories.count).to eq(1)
  end

  it "should store history on update" do
    model = history_concern_class.make
    expect(model.histories.count).to eq(1)
    model.name = "New name"
    model.save!
    expect(model.name).to eq("New name")
    expect(model.histories.count).to eq(2)
    expect(model.histories.last.name).to eq("New name")
  end

  it "should set valid_to in history on update" do
    model = history_concern_class.make
    model.name = "New name"
    model.save!
    expect(model.histories.count).to eq(2)
    expect(model.histories.first.valid_to.to_i).to eq(model.updated_at.to_i)
    expect(model.histories.last.valid_to).to be_nil
  end

  it "should set valid_to in history before delete" do
    model = history_concern_class.make
    expect(model.histories.count).to eq(1)
    expect(model.histories.last.valid_to).to be_nil

    stub_time '2020-01-01 10:00:00 -0500'

    model.destroy
    histories = model.histories
    expect(history_concern_class.where(id: model.id).count).to eq(0)
    expect(histories.count).to eq(1)
    expect(histories.last.valid_to).to eq(Time.now)
  end

  it "shouldn't get current history when destroyed" do
    model = history_concern_class.make
    model.destroy
    model_history = model.current_history
    expect(model_history).to be_nil
  end

  it "should get current history for new model" do
    model = history_concern_class.make
    model_history = model.current_history
    expect(model_history).to be
    assert_model_equals_history model, model_history
    expect(model_history.valid_to).to be_nil
    expect(model_history.valid_since.to_i).to eq(model.created_at.to_i)
  end

  it "should get current history for updated model" do
    stub_time '2010-01-01 09:00:00 -0500'
    model = history_concern_class.make

    stub_time '2010-02-02 09:00:00 -0500'
    model.name = "new name"
    model.save!

    model_history = model.current_history
    expect(model_history).to be
    expect(model_history.valid_to).to be_nil
    assert_model_equals_history model, model_history
    expect(model_history.valid_since.to_i).to eq(model.updated_at.to_i)
  end

  it "should not get new elements in history for date" do
    collection = Collection.make

    stub_time '2011-01-01 10:00:00 -0500'

    history_concern_class.make name: '1 last year', collection_id: collection.id
    history_concern_class.make name: '2 last year', collection_id: collection.id

    stub_time '2012-06-05 12:17:58 -0500'

    history_concern_class.make name: '3 today', collection_id: collection.id
    history_concern_class.make name: '4 today', collection_id: collection.id

    date = '2011-01-01 10:00:00 -0500'.to_time

    histories = collection.send(history_concern_histories.downcase).at_date(date)
    expect(histories.count).to eq(2)
  end

  def assert_model_equals_history(model, history)
    model.attributes.keys.each do |key|
      expect(model[key]).to eq(history[key]) unless ['id', 'created_at', 'updated_at'].include? key
    end
    expect(history[history_concern_foreign_key]).to eq(model.id)
  end
end
