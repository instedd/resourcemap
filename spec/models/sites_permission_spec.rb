require 'spec_helper'

describe SitesPermission, :type => :model do
  it { is_expected.to belong_to :membership }

  describe "convert to json" do
    describe '#to_json' do
      subject { super().to_json }
      it { is_expected.not_to include "\"id\":" }
    end

    describe '#to_json' do
      subject { super().to_json }
      it { is_expected.not_to include "\"membership_id\":" }
    end

    describe '#to_json' do
      subject { super().to_json }
      it { is_expected.not_to include "\"created_at\":" }
    end

    describe '#to_json' do
      subject { super().to_json }
      it { is_expected.not_to include "\"updated_at\":" }
    end
  end
end
