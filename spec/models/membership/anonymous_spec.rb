require 'spec_helper'

describe Membership::Anonymous, :type => :model do
  let(:user) { User.make }
  let(:collection) { user.create_collection(Collection.make_unsaved) }
  let(:anonymous) { Membership::Anonymous.new collection, user }

  describe '#as_json' do
    subject { anonymous.as_json }

    describe '[:name]' do
      subject { super()[:name] }
      it { is_expected.to eq('none') }
    end

    describe '[:location]' do
      subject { super()[:location] }
      it { is_expected.to eq('none') }
    end
  end

  ['name', 'location'].each do |builtin_field|
    describe "##{builtin_field}_default_permission" do
      subject { anonymous.send("#{builtin_field}_permission") }
      it { is_expected.to eq('none') }
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
      expect(layers_matching.length).to eq(1)

      layer_json = layers_matching[0]

      expect(layer_json[:read]).to eq(false)
      expect(layer_json[:write]).to eq(false)
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
        expect(layers_matching.length).to eq(1)

        layer_json = layers_matching[0]
        expect(layer_json[:read]).to eq(level == "read")
        expect(layer_json[:write]).to eq(level == "false")
      end
    end
  end

  ["true", "false"].each do |access|
    describe "set layer's read access" do
      let(:layer) { collection.layers.make }

      it '' do
        anonymous.activity_user = user
        anonymous.set_layer_access(layer.id, "read", access)
        if (access == "true")
          expect(anonymous.layer_access(layer.id)).to eq("read")
        else
          expect(anonymous.layer_access(layer.id)).to eq("none")
        end
      end
    end
  end

  ["name","location"].each do |object|
    describe "set #{object}" do
      ["none","read"].each do |level|
        describe "#{level}able permissions" do
          it '' do
            anonymous.activity_user = user
            anonymous.set_access(object,level)
            expect(anonymous.send("#{object}_permission")).to eq(level)
          end
        end
      end
    end
  end

end
