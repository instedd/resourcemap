require 'spec_helper'
require 'spec_helper'

describe Field::TireConcern do
  let!(:field) { Field::NumericField.make :id => 23 }

  it "returns a single field" do
    Field.where_es_code_is("23").should be_a_kind_of Field
  end
end
