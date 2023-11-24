require 'spec_helper'
require 'spec_helper'

describe Field::ElasticsearchConcern, :type => :model do
  let!(:field) { Field::NumericField.make! :id => 23 }

  it "returns a single field" do
    expect(Field.where_es_code_is("23")).to be_a_kind_of Field
  end
end
