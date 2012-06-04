require 'spec_helper'
require File.expand_path(File.join(File.dirname(__FILE__), 'treetop_helper'))

describe ExecVisitor, "Process query command" do
  pending do
    before(:all) do
      @visitor = ExecVisitor.new
    end

    before(:each) do
      parser = CommandParser.new
    @collection = Collection.make(:name => 'Healt Center')
    @layer = @collection.layers.make(:name => "default")
    @layer.fields.make(:code => "AB", :ord => 1, :kind => "numeric")
    @user = User.make(:phone_number => '85512345678')
    @collection.layer_memberships.create(:user => @user, :layer_id => @layer.id, :read => true, :write => true)
    @collection.memberships.create(:user => @user, :admin => false)
    
    @node = parser.parse("dyrm q #{@collection.id} AB>5").command
      @node.sender = @user
    @properties =[{:code=>"AB", :value=>"26"}]  
    end

  it "should recognize collection_id equals to 2" do
    @node.layer_id.value.should == @collection.id
    end

  it "should recognize property name equals to AB" do
    @node.conditional_expression.name.text_value.should == 'AB'
    end

    it "should recognize conditional operator equals to greater than sign" do
      @node.conditional_expression.operator.text_value.should == '>'
    end

    it "should recognize property value equals to 5" do
      @node.conditional_expression.value.value.should == 5
    end

  it "should find collection by id" do
    Collection.should_receive(:find_by_id).with(@collection.id).and_return(@collection)
      @visitor.visit_query_command @node
    end

  it "should user can view collection" do
    @visitor.can_view?(@properties[0], @node.sender, @collection).should be_true
    end

    it "should query resources with condition options" do
    Collection.should_receive(:find_by_id).with(@collection.id).and_return(@collection)
    @collection.should_receive(:query_sites).with({ :code => 'AB', :operator => '>', :value => '5'})
      @visitor.visit_query_command @node
    end

    describe "Reply message" do
      context "valid criteria" do
      it "should get Siemreap Health Center when their Ambulance property greater than 5" do
        f1 = @layer.fields.make(:id => 10, :name => "Ambulance", :code => "AB", :ord => 1, :kind => "numeric")
        f2 = @layer.fields.make(:id => 11, :name => "Doctor", :code => "DO", :ord => 2, :kind => "numeric")
        @collection.sites.make(:name => 'Siemreap Healt Center', :properties => {"10"=>15, "11"=>40})
        @visitor.visit_query_command(@node).should eq('["AB"] in Siemreap Healt Center, 15')
        end

      it "should return no result for public collection" do
        @collection.public = true and @collection.save
        @visitor.visit_query_command(@node).should == "[\"AB\"] in There is no site matched"
        end
      end

      context "invalid criteria" do
        before(:each) do
          @bad_user = User.make :phone_number => "222"
        end

      it "should return 'No resource available' when collection does not have any site" do
        @visitor.visit_query_command(@node).should == "[\"AB\"] in There is no site matched"
        end

      it "should return 'No site available' when site_properties does not match with condition" do
        site = Site.make(:collection => @collection)
        @visitor.visit_query_command(@node).should == "[\"AB\"] in There is no site matched" 
        end

        it "should raise error when the sender is not a dyrm user" do
          @node.sender = nil
          lambda {
            @visitor.visit_query_command(@node)
          }.should raise_error(RuntimeError, ExecVisitor::MSG[:can_not_query])
        end

      it "should raise error when the sender is not a collection member" do
          @node.sender = @bad_user
          lambda {
            @visitor.visit_query_command(@node)
          }.should raise_error(RuntimeError, ExecVisitor::MSG[:can_not_query])
        end
      end

      context "when property value is not a number" do
        before(:each) do
          parser = CommandParser.new
        @node = parser.parse("dyrm q #{@collection.id} PN=Phnom Penh").command
          @node.sender = @user
        end

        it "should query property pname equals to Phnom Penh" do
        @layer.fields.make(:id => 22, :name => "pname", :code => "PN", :ord => 1, :kind => "text")
        @collection.sites.make(:name => 'Bayon', :properties => {"22"=>"Phnom Penh"})
        @visitor.visit_query_command(@node).should eq "[\"PN\"] in Bayon, Phnom Penh" 
        end
      end
    end
  end
end

describe ExecVisitor, "Process update command" do
  pending do
    before(:all) do
      @visitor = ExecVisitor.new
    end

    before(:each) do
      parser = CommandParser.new
    @collection = Collection.make
    @user = User.make(:phone_number => '85512345678')
    @collection.memberships.create(:user => @user, :admin => false)
    @layer = @collection.layers.make(:name => "default")
    @f1 = @layer.fields.make(:id => 22, :code => "ambulances", :name => "Ambulance", :ord => 1, :kind => "numeric")
    @f2 = @layer.fields.make(:id => 23, :code => "doctors", :name => "Doctor", :ord => 1, :kind => "numeric")
    @site = @collection.sites.make(:name => 'Siemreap Healt Center', :properties => {"22"=>5, "23"=>2}, :id_with_prefix => "AB1")
    @collection.layer_memberships.create(:user => @user, :layer_id => @layer.id, :read => true, :write => true)
    @node = parser.parse('dyrm u AB1 ambulances=15,doctors=20').command
      @node.sender = @user
    end

  it "should recognize resource_id equals to AB1" do
    @node.resource_id.text_value.should == 'AB1'
    end

  it "should recognize first property setting ambulances to 15" do
      property = @node.property_list.assignment_expression
    property.name.text_value.should == 'ambulances'
    property.value.value.should == 15
    end

  it "should recognize second property setting doctors to 20" do
      property = @node.property_list.next
      property.name.text_value.should == 'doctors'
    property.value.value.should == 20
    end

  it "should find resource with id AB1" do
    Site.should_receive(:find_by_id_with_prefix).with('AB1')
      lambda {
        @visitor.visit_update_command @node
      }.should raise_error
    end

    it "should user can update resource" do
    @visitor.can_update?(@node.property_list, @node.sender, @site).should be_true
    end

    it "should validate sender can not update resource" do
      sender = User.make(:phone_number => "111")
    @visitor.can_update?(@node.property_list, sender, @site).should be_false
    end

    it "should raise exception when do not have permission" do
    site = Site.make
    Site.should_receive(:find_by_id_with_prefix).with('AB1').and_return(site)

      @node.sender = User.make(:phone_number => '123')
      lambda {
        @visitor.visit_update_command(@node)
      }.should raise_error(RuntimeError, ExecVisitor::MSG[:can_not_update])
    end

  it "should update property  of the site" do
    Site.should_receive(:find_by_id_with_prefix).with('AB1').and_return(@site)
    @visitor.should_receive(:can_update?).and_return(true)
    @site.should_receive(:update_properties).with(@site, @node.sender, [{:code=>"ambulances", :value=>"15"}, {:code=>"doctors", :value=>"20"}])
      @visitor.visit_update_command(@node).should == ExecVisitor::MSG[:update_successfully]
  end

  it "should update field Ambulance to 15 and Doctor to 20" do
    @visitor.visit_update_command(@node).should == ExecVisitor::MSG[:update_successfully]
    site = Site.find_by_id_with_prefix('AB1')
    site.properties[@f1.id.to_s].to_i.should == 15
    site.properties[@f2.id.to_s].to_i.should == 20
    end
end
