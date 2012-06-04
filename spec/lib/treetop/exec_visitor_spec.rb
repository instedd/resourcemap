require 'spec_helper'
require File.expand_path(File.join(File.dirname(__FILE__), 'treetop_helper'))

describe ExecVisitor, "Process query command" do
  pending do
    before(:all) do
      @visitor = ExecVisitor.new
    end

    before(:each) do
      parser = CommandParser.new
      @layer = Layer.make(:id => 2, :name => 'Clinic')
      @template = @layer.templates.make(:name => "default")
      @pname = @template.properties.make(:name => "pname")
      @user = User.make(:phone_number => '999')
      @layer.memberships.create(:user => @user, :role => 'User', :access_rights => 1)

      @node = parser.parse('dyrm q 2 beds>5').command
      @node.sender = @user
    end

    it "should recognize layer_id equals to 2" do
      @node.layer_id.value.should == 2
    end

    it "should recognize property name equals to beds" do
      @node.conditional_expression.name.text_value.should == 'beds'
    end

    it "should recognize conditional operator equals to greater than sign" do
      @node.conditional_expression.operator.text_value.should == '>'
    end

    it "should recognize property value equals to 5" do
      @node.conditional_expression.value.value.should == 5
    end

    it "should find layer by id" do
      Layer.expects(:find_by_id).with(2).returns(@layer)
      @visitor.visit_query_command @node
    end

    it "should user can view layer" do
      @visitor.can_view?(@node.sender, @layer).should be_true
    end

    it "should query resources with condition options" do
      Layer.expects(:find_by_id).with(2).returns(@layer)
      @layer.expects(:query_resources).with({ :name => 'beds', :operator => '>', :value => '5'})

      @visitor.visit_query_command @node
    end

    describe "Reply message" do
      context "valid criteria" do
        it "should get Calmette and Bayon when their beds property greater than 5" do
          beds = @template.properties.make(:name => "beds")
          r1 = Resource.make(:name => 'Calmette', :layer => @layer)
          r1.resource_properties.make(:property => beds, :value => '10')

          r2 = Resource.make(:name => 'Bayon', :layer => @layer)
          r2.resource_properties.make(:property => beds, :value => '6')

          @visitor.visit_query_command(@node).should eq('"beds" in Calmette=10, Bayon=6')
        end

        it "should return no result for public layer" do
          @layer.is_public = true and @layer.save
          @visitor.visit_query_command(@node).should == ExecVisitor::MSG[:query_not_match]
        end
      end

      context "invalid criteria" do
        before(:each) do
          @bad_user = User.make :phone_number => "222"
        end

        it "should return 'No resource available' when layer 2 does not have any resource" do
          @visitor.visit_query_command(@node).should == ExecVisitor::MSG[:query_not_match]
        end

        it "should return 'No resource available' when resource property does not match with condition" do
          resource = Resource.make(:layer => @layer)
          @visitor.visit_query_command(@node).should == ExecVisitor::MSG[:query_not_match]
        end

        it "should raise error when the sender is not a dyrm user" do
          @node.sender = nil
          lambda {
            @visitor.visit_query_command(@node)
          }.should raise_error(RuntimeError, ExecVisitor::MSG[:can_not_query])
        end

        it "should raise error when the sender is not a layer member" do
          @node.sender = @bad_user
          lambda {
            @visitor.visit_query_command(@node)
          }.should raise_error(RuntimeError, ExecVisitor::MSG[:can_not_query])
        end
      end

      context "when property value is not a number" do
        before(:each) do
          parser = CommandParser.new
          @node = parser.parse('dyrm q 2 pname=Phnom Penh').command
          @node.sender = @user
        end

        it "should query property pname equals to Phnom Penh" do
          resource = @layer.resources.make(:id => 100, :name => 'Bayon')
          resource.resource_properties.make(:property => @pname, :value => 'Phnom Penh')

          @visitor.visit_query_command(@node).should == '"pname=Phnom Penh" in Bayon'
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
      @layer = Layer.make
      @user = User.make(:phone_number => '999')
      @layer.memberships.create(:user => @user, :role => 'User', :access_rights => 2)
      @template = @layer.templates.make(:name => "default")
      @resource = @layer.resources.make(:id_with_prefix => "AB100")
      @resource.resources_memberships.make(:user => @user)
      @node = parser.parse('dyrm u AB100 beds=5, doctors=2').command
      @node.sender = @user
    end

    it "should recognize resource_id equals to AB100" do
      @node.resource_id.text_value.should == 'AB100'
    end

    it "should recognize first property setting beds to 5" do
      property = @node.property_list.assignment_expression
      property.name.text_value.should == 'beds'
      property.value.value.should == 5
    end

    it "should recognize second property setting doctors to 2" do
      property = @node.property_list.next
      property.name.text_value.should == 'doctors'
      property.value.value.should == 2
    end

    it "should find resource with id AB100" do
      Resource.expects(:find_by_id_with_prefix).with('AB100')
      lambda {
        @visitor.visit_update_command @node
      }.should raise_error
    end

    it "should user can update resource" do
      @visitor.can_update?(@node.sender, @resource).should be_true
    end

    it "should validate sender can not update resource" do
      sender = User.make(:phone_number => "111")
      @visitor.can_update?(sender, @resource).should be_false
    end

    it "should raise exception when do not have permission" do
      resource = Resource.make
      Resource.expects(:find_by_id_with_prefix).with('AB100').returns(resource)

      @node.sender = User.make(:phone_number => '123')
      lambda {
        @visitor.visit_update_command(@node)
      }.should raise_error(RuntimeError, ExecVisitor::MSG[:can_not_update])
    end

    it "should update property beds of the resource" do
      resource = Resource.make
      Resource.expects(:find_by_id_with_prefix).with('AB100').returns(resource)
      @visitor.expects(:can_update?).returns(true)
      resource.expects(:update_properties).with(@node.sender, [{:name=>"beds", :value=>"5"}, {:name=>"doctors", :value=>"2"}])

      @visitor.visit_update_command(@node).should == ExecVisitor::MSG[:update_successfully]
    end

    it "should update property beds to 5 and doctors to 2" do
      beds = @template.properties.make(:name => "beds")
      doctors = @template.properties.make(:name => "doctors")
      Resource.make(:id_with_prefix => 'AB100', :name => 'Calmette', :layer => @layer) do |resource|
        resource.resource_properties.make(:property => beds, :value => '10')
        resource.resource_properties.make(:property => doctors, :value => '10')
      end

      @visitor.visit_update_command(@node).should == ExecVisitor::MSG[:update_successfully]

      resource = Resource.find_by_id_with_prefix('AB100')
      resource.resource_properties[0].value.to_i.should == 5
      resource.resource_properties[1].value.to_i.should == 2
    end

    it "should raise if trying to create new property doctors when there is only beds property" do
      beds = @template.properties.make(:name => "beds")
      @resource.resource_properties.make(:property => beds, :value => '10')

      lambda { @visitor.visit_update_command(@node) }.should raise_error

      Property.find_by_name("doctors").should be_nil
      @resource.reload.should have(1).resource_properties
      @resource.resource_properties.first.value.to_i.should eq(10)
    end

    it "should add doctors property when it exists in property template" do
      beds = @template.properties.make(:name => "beds")
      doctors = @template.properties.make(:name => "doctors")

      @resource.resource_properties.make(:property => beds, :value => '10')

      @resource.resource_properties.count.should == 1
      @visitor.visit_update_command(@node).should == ExecVisitor::MSG[:update_successfully]
      @resource.resource_properties.count.should == 2
      @resource.resource_properties[0].value.to_i.should == 5
      @resource.resource_properties[1].value.to_i.should == 2
    end

    context "when property value is not a number" do
      before(:each) do
        parser = CommandParser.new
        @node = parser.parse('dyrm u AQ100 pname=Phnom Penh').command
        @node.sender = @user
      end

      it "should update property pname" do
        resource = @layer.resources.make :id_with_prefix => 'AQ100'
        property = @template.properties.make(:name => "pname")
        resource.resource_properties.make(:id => 999, :property => property, :value => 'foo')

        @visitor.visit_update_command(@node).should == ExecVisitor::MSG[:update_successfully]
        resource.resource_properties[0].value.should == 'Phnom Penh'
      end
    end
  end
end
