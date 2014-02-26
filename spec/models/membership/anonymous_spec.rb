require 'spec_helper'

describe Membership::Anonymous do
  let(:user) { User.make }
  let(:collection) { user.create_collection(Collection.make_unsaved) }
  let(:anonymous) { Membership::Anonymous.new collection, user }

  describe '#as_json' do
    subject { anonymous.as_json }

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
      let(:anonymous2) { Membership::Anonymous.new collection2, user }
      subject { anonymous2.send("#{builtin_field}_permission") }
      it { should eq('read') }
    end
  end

  describe "default_layer_permissions" do
    let(:layer) { collection.layers.make }

    subject{
      layer
      anonymous.as_json[:layers]
    }

    it "should be false" do
      layers_matching = subject.select{|l| l[:layer_id] == layer.id}
      layers_matching.length.should eq(1)

      layer_json = layers_matching[0]

      layer_json[:read].should eq(false)
      layer_json[:write].should eq(false)
    end
  end

  ['read', 'none'].each do |level|
    describe "#{level}able layers" do
      let(:layer) { collection.layers.make({anonymous_user_permission: level}) }

      subject {
        layer
        anonymous.as_json[:layers]
      }

      it "should have #{level}able permissions" do
        layers_matching = subject.select{|l| l[:layer_id] == layer.id}
        layers_matching.length.should eq(1)

        layer_json = layers_matching[0]
        layer_json[:read].should eq(level == "read")
        layer_json[:write].should eq(level == "false")
      end
    end
  end

  ["true", "false"].each do |access|
    describe "set layer's read access" do
      let(:layer) { collection.layers.make }

      it '' do
        anonymous.set_layer_access(layer.id, "read", access)
        if (access == "true")
          anonymous.layer_access(layer.id).should eq("read")
        else
          anonymous.layer_access(layer.id).should eq("none")
        end
      end
    end
  end

end
