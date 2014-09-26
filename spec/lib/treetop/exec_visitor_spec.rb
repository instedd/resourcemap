require 'spec_helper'
require File.expand_path(File.join(File.dirname(__FILE__), 'treetop_helper'))

describe ExecVisitor, "Process query command" do
  before(:all) do
    @visitor = ExecVisitor.new
  end

  before(:each) do
    parser = CommandParser.new
    @collection = Collection.make(:name => 'Healt Center')
    @layer = @collection.layers.make(:name => "default")
    @user = User.make(:phone_number => '85512345678')
    @f1 = @layer.numeric_fields.make :id => 10, :name => "Ambulance", :code => "AB", :ord => 1
    @f2 = @layer.numeric_fields.make :id => 11, :name => "Doctor", :code => "DO", :ord => 2
    membership = @collection.memberships.create(:user => @user, :admin => false)
    membership.layer_memberships.create(:layer_id => @layer.id, :read => true, :write => true)

    @node = parser.parse("dyrm q #{@collection.id} AB>5").command
    @node.sender = @user
    @properties =[{:code=>"AB", :value=>"26"}]
  end

  it "should recognize collection_id equals to @collection.id" do
    expect(@node.collection_id.value).to eq(@collection.id)
  end

  it "should recognize property name equals to AB" do
    expect(@node.conditional_expression.name.text_value).to eq('AB')
  end

  it "should recognize conditional operator equals to greater than sign" do
    expect(@node.conditional_expression.operator.text_value).to eq('>')
  end

  it "should recognize property value equals to 5" do
    expect(@node.conditional_expression.value.value).to eq(5)
  end

  it "should find collection by id" do
    expect(Collection).to receive(:find_by_id).with(@collection.id).and_return(@collection)
    @visitor.visit_query_command @node
  end

  it "should user can view collection" do
    expect(@visitor.can_view?(@properties[0], @node.sender, @collection)).to be_truthy
  end

  it "should query resources with condition options" do
    expect(Collection).to receive(:find_by_id).with(@collection.id).and_return(@collection)
    expect(@collection).to receive(:query_sites).with({ :code => 'AB', :operator => '>', :value => '5'})
    @visitor.visit_query_command @node
  end

  describe "Reply message" do
    context "valid criteria" do
      it "should get Siemreap Health Center when their Ambulance property greater than 5" do
        @collection.sites.make(:name => 'Siemreap Healt Center', :properties => {"10"=>15, "11"=>40})
        expect(@visitor.visit_query_command(@node)).to eq('["AB"] in Siemreap Healt Center=15')
      end

      it "should return no result for public collection" do
        @collection.anonymous_name_permission = true and @collection.save
        expect(@visitor.visit_query_command(@node)).to eq("[\"AB\"] in There is no site matched")
      end
    end

    context "invalid criteria" do
      before(:each) do
        @bad_user = User.make :phone_number => "222"
      end

      it "should return 'No resource available' when collection does not have any site" do
        expect(@visitor.visit_query_command(@node)).to eq("[\"AB\"] in There is no site matched")
      end

      it "should return 'No site available' when site_properties does not match with condition" do
        site = Site.make(:collection => @collection)
        expect(@visitor.visit_query_command(@node)).to eq("[\"AB\"] in There is no site matched")
      end

      it "should raise error when the sender is not a dyrm user" do
        @node.sender = nil
        expect {
          @visitor.visit_query_command(@node)
        }.to raise_error(RuntimeError, ExecVisitor::MSG[:can_not_query])
      end

      it "should raise error when the sender is not a collection member" do
        @node.sender = @bad_user
        expect {
          @visitor.visit_query_command(@node)
        }.to raise_error(RuntimeError, ExecVisitor::MSG[:can_not_query])
      end
    end

    context "when property value is not a number" do
      before(:each) do
        parser = CommandParser.new
        @node = parser.parse("dyrm q #{@collection.id} PN=Phnom Penh").command
        @node.sender = @user
      end

      it "should query property pname equals to Phnom Penh" do
        @layer.text_fields.make :id => 22, :name => "pname", :code => "PN", :ord => 1
        @collection.sites.make :name => 'Bayon', :properties => {"22"=>"Phnom Penh"}
        expect(@visitor.visit_query_command(@node)).to eq "[\"PN\"] in Bayon=Phnom Penh"
      end
    end
  end
end

describe ExecVisitor, "Process update command" do
  before(:all) do
    @visitor = ExecVisitor.new
  end

  before(:each) do
    parser = CommandParser.new
    @collection = Collection.make
    @user = User.make(:phone_number => '85512345678')
    membership = @collection.memberships.create(:user => @user, :admin => false)
    @layer = @collection.layers.make(:name => "default")
    @f1 = @layer.numeric_fields.make(:id => 22, :code => "ambulances", :name => "Ambulance", :ord => 1)
    @f2 = @layer.numeric_fields.make(:id => 23, :code => "doctors", :name => "Doctor", :ord => 1)
    @site = @collection.sites.make(:name => 'Siemreap Healt Center', :properties => {"22"=>5, "23"=>2}, :id_with_prefix => "AB1")
    @site.user = @user
    membership.layer_memberships.create(:layer_id => @layer.id, :read => true, :write => true)
    @node = parser.parse('dyrm u AB1 ambulances=15,doctors=20').command
    @node.sender = @user
  end

  it "should recognize resource_id equals to AB1" do
    expect(@node.resource_id.text_value).to eq('AB1')
  end

  it "should recognize first property setting ambulances to 15" do
    property = @node.property_list.assignment_expression
    expect(property.name.text_value).to eq('ambulances')
    expect(property.value.value).to eq(15)
  end

  it "should recognize second property setting doctors to 20" do
    property = @node.property_list.next
    expect(property.name.text_value).to eq('doctors')
    expect(property.value.value).to eq(20)
  end

  it "should find resource with id AB1" do
    expect(Site).to receive(:find_by_id_with_prefix).with('AB1')
    expect {
      @visitor.visit_update_command @node
    }.to raise_error
  end

  it "should user can update resource" do
    expect(@visitor.can_update?(@node.property_list, @node.sender, @site)).to be_truthy
  end

  it "should validate sender can not update resource" do
    sender = User.make(:phone_number => "111")
    expect(@visitor.can_update?(@node.property_list, sender, @site)).to be_falsey
  end

  it "should raise exception when do not have permission" do
    site = Site.make
    expect(Site).to receive(:find_by_id_with_prefix).with('AB1').and_return(site)

    @node.sender = User.make(:phone_number => '123')
    expect {
      @visitor.visit_update_command(@node)
    }.to raise_error(RuntimeError, ExecVisitor::MSG[:can_not_update])
  end

  it "should update property  of the site" do
    expect(Site).to receive(:find_by_id_with_prefix).with('AB1').and_return(@site)
    expect(@visitor).to receive(:can_update?).and_return(true)
    expect(@visitor).to receive(:update_properties).with(@site, @node.sender, [{:code=>"ambulances", :value=>"15"}, {:code=>"doctors", :value=>"20"}])
    expect(@visitor.visit_update_command(@node)).to eq(ExecVisitor::MSG[:update_successfully])
  end

  it "should update field Ambulance to 15 and Doctor to 20" do
    expect(@visitor.visit_update_command(@node)).to eq(ExecVisitor::MSG[:update_successfully])
    site = Site.find_by_id_with_prefix('AB1')
    expect(site.properties[@f1.es_code].to_i).to eq(15)
    expect(site.properties[@f2.es_code].to_i).to eq(20)
  end
end
