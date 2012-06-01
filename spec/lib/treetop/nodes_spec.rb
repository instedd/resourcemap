require 'spec_helper'
require File.expand_path(File.join(File.dirname(__FILE__), 'treetop_helper'))

# parse valid query command
describe QueryCommandNode, "when parse valid query command" do
	include PropertyAssertionHelper
	before(:all) do
		@parser = CommandParser.new
	end
	
	before(:each) do
		@node = @parser.parse('dyrm q 1 beds>=8').command
	end
	
	it "should layer_id equal to 1" do
		@node.layer_id.value.should == 1
	end
	
	it "should condition name equal to 'beds'" do
		@node.conditional_expression.name.text_value == 'beds'
	end
	
	it "should condition operator equal to '>='" do
		@node.conditional_expression.operator.text_value == '>='
	end
	
	it "should condition value equal to 8" do
		@node.conditional_expression.value.value == 8
	end
	
end

# parse valid update command
describe UpdateCommandNode, "when parse valid update command" do
	include PropertyAssertionHelper
	before(:all) do
		@parser = CommandParser.new
	end
	
	before(:each) do
		@node = @parser.parse('dyrm u AA382 beds=5').command
	end
	
	it "should be UpdateCommandNode" do
		@node.kind_of?(UpdateCommandNode) == true
	end
	
	it "should resource_id equal to AA382" do
		@node.resource_id.text_value.should == 'AA382'
	end
	
	it "should property_list have one property" do
		@node.property_list.terminal? == true
	end	
	
	it "should property name equal to 'beds' and value equal to 5" do
		assert_property 'beds', 5, @node.property_list
	end
	
end

# parse update command with more properties
describe UpdateCommandNode, "when parse valid update command with more properties" do
	include PropertyAssertionHelper
	before(:all) do
		@parser = CommandParser.new
	end
	
	before(:each) do
		@node = @parser.parse('dyrm u AA382 beds=5, doctors=2, vaccine=20').command
	end
	
	it "should be QueryCommandNode" do
		@node.kind_of?(QueryCommandNode) == true
	end
	
	it "should resource_id equal to AA382" do
		@node.resource_id.text_value.should == 'AA382'
	end
	
	it "should the first property name equal to 'beds' and value equal to 5" do
		assert_property 'beds', 5, @node.property_list
	end
	
	it "should the second property name equal to 'doctors' and value equal to 2" do
		assert_property 'doctors', 2, @node.property_list.next
	end
	
	it "should the third property name equal to 'vaccine' and value equal to 20" do
		assert_property 'vaccine', 20, @node.property_list.next.next
	end
	
end

# parse invalid command
describe "when parse invalid command" do
	before(:all) do
		@parser = CommandParser.new
	end
	
	it "could not parse number as command node" do
		node = @parser.parse('99999')
		node.nil? == true
	end
	
	it "could not parse space as command node" do
		node = @parser.parse('  ')
		node.nil? == true
	end
	
	it "could not parse single word as command node" do
		node = @parser.parse('Hello')
		node.nil? == true
	end
	
	it "could not parse normal paragraph as command node" do
		node = @parser.parse('Hello world ruby.')
		node.nil? == true
	end
	
	it "could not parse conditional_expression as command node" do
		node = @parser.parse('beds>=5')
		node.nil? == true
	end
	
	it "could not parse assignment_expression as command node" do
		node = @parser.parse('beds=5')
		node.nil? == true
	end
	
	it "could not parse property_list as command node" do
		node = @parser.parse('foo=1, bar=2')
		node.nil? == true
	end
end

