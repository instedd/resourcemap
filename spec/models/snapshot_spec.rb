require 'spec_helper'

describe Snapshot do
  let!(:snapshot) { Snapshot.make }

  it { should validate_uniqueness_of(:name).scoped_to(:collection_id) }

end
