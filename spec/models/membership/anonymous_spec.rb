require 'spec_helper'

describe Anonymous do
  let(:user) { User.make }
  let(:collection) { user.create_collection(Collection.make_unsaved) }
  let(:anonymous) { Anonymous.new collection, user }

  describe '#to_json' do
    subject { anonymous.to_json }

    its([:name]) { should eq('none') }
    its([:location]) { should eq('none') }
  end

  ['name', 'location'].each do |builtin_field|
    describe "##{builtin_field}_private_permission" do
      subject { anonymous.send("#{builtin_field}_permission") }
      it { should eq('none') }
    end

    describe "##{builtin_field}_public_permission" do
      let(:collection2) {user.create_collection(Collection.make_unsaved({public: true}))}
      let(:anonymous2) { Anonymous.new collection2, user }
      subject { anonymous2.send("#{builtin_field}_permission") }
      it { should eq('read') }
    end
  end

  describe "default_layer_permission" do
      let(:layer) { collection.layers.make }
      subject{
        layer
        anonymous.to_json[layer.id.to_s]
      }
      it {should eq("none")}
  end

  ['read', 'none'].each do |level|
    describe "#{level}able layers" do
      let(:layer) { collection.layers.make({anonymous_user_permission: level}) }

      subject {
        layer
        anonymous.to_json[layer.id.to_s]
      }

      it { should eq(level) }
    end
  end

  ['read', 'none'].each do |level|
    describe "set_layer_#{level}able_access" do
      let(:layer) { collection.layers.make }

      it '' do
        anonymous.set_layer_access(layer.id, level)
        anonymous.to_json[layer.id.to_s].should eq(level)
      end
    end
  end

end
