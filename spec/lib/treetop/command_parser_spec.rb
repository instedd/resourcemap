# encoding = UTF-8
require 'spec_helper'
require 'polyglot'
require File.expand_path(File.join(File.dirname(__FILE__), 'treetop_helper'))

Treetop.load 'lib/treetop/command'

describe CommandParser do
  pending do
    before(:all) do
      @parser = CommandParser.new
    end

    it "should parse query command with dyrm prefix" do
      node = @parser.parse('dyrm q 1 beds>10')
      node.command.should be_is_a QueryCommandNode
      node.command.layer_id.value.should == 1

      condition = node.command.conditional_expression
      condition.name.text_value.should == 'beds'
      condition.operator.text_value.should == '>'
      condition.value.value.should == 10
    end

    it "should parse query command with dyrm prefix and '\\n' suffix" do
      node = @parser.parse("dyrm q 1 beds>10\n")
      node.command.should be_is_a QueryCommandNode
    end

    it "should parse query command with dyrm prefix and space previous '\\n' suffix" do
      node = @parser.parse("dyrm q 1 beds>10 \n")
      node.command.should be_is_a QueryCommandNode
    end

    it "should parse query command with dyrm prefix and '\\r' suffix" do
      node = @parser.parse("dyrm q 1 beds>10\r")
      node.command.should be_is_a QueryCommandNode
    end

    it "should parse query command with dyrm prefix and space previous '\\r' suffix" do
      node = @parser.parse("dyrm q 1 beds>10 \r")
      node.command.should be_is_a QueryCommandNode
    end

    it "should parse query command with dyrm prefix and '\\n\\r' suffix" do
      node = @parser.parse("dyrm q 1 beds>10\n\r")
      node.command.should be_is_a QueryCommandNode
    end

    it "should parse query command with dyrm prefix and space previos '\\n\\r' suffix" do
      node = @parser.parse("dyrm q 1 beds>10\n\r")
      node.command.should be_is_a QueryCommandNode
    end

    it "should parse update command with dyrm prefix" do
      node = @parser.parse('dyrm u AA111 beds=222,doctors=55')
      node.command.should be_is_a UpdateCommandNode
      node.command.resource_id.text_value.should == 'AA111'

      properties = node.command.property_list
      first = properties.assignment_expression
      first.name.text_value.should == "beds"
      first.value.value.should == 222

      second = properties.next
      second.name.text_value.should == "doctors"
      second.value.value.should == 55
    end

    it "should parse update command with dyrm prefix and 1 comma suffix" do
      node = @parser.parse("dyrm u AA111 beds=222,")
      node.command.should be_is_a UpdateCommandNode
    end

    it "should parse update command with dyrm prefix and many comma suffix" do
      node = @parser.parse("dyrm u AA111 beds=222,")
      node.command.should be_is_a UpdateCommandNode
    end

    it "should parse update command with dyrm prefix and '\\n' suffix" do
      node = @parser.parse("dyrm u AA111 beds=222\n")
      node.command.should be_is_a UpdateCommandNode
    end

    it "should parse update command with dyrm prefix and space previous '\\n' suffix" do
      node = @parser.parse("dyrm u AA111 beds=222 \n")
      node.command.should be_is_a UpdateCommandNode
    end

    it "should parse update command with dyrm prefix and '\\r' suffix" do
      node = @parser.parse("dyrm u AA111 beds=222\r")
      node.command.should be_is_a UpdateCommandNode
    end

    it "should parse update command with dyrm prefix and space previous '\\r' suffix" do
      node = @parser.parse("dyrm u AA111 beds=222 \r")
      node.command.should be_is_a UpdateCommandNode
    end

    it "should parse update command with dyrm prefix and '\\n\\r' suffix" do
      node = @parser.parse("dyrm u AA111 beds=222\n\r")
      node.command.should be_is_a UpdateCommandNode
    end

    it "should parse update command with dyrm prefix and space previous '\\n\\r' suffix" do
      node = @parser.parse("dyrm u AA111 beds=222 \n\r")
      node.command.should be_is_a UpdateCommandNode
    end

    pending "should parse dyrm u 3 beds=10 20"

    pending "should parse dyrm u 12 x-ray=10   "

    it "should parse query command with equal condition" do
      node = @parser.parse('dyrm q 1 pname=kandal')
      node.command.should be_is_a QueryCommandNode
      node.command.layer_id.value.should == 1

      condition = node.command.conditional_expression
      condition.name.text_value.should == 'pname'
      condition.operator.text_value.should == '='
      condition.value.text_value.should == 'kandal'
    end

    it "should parse update command with condition value as string" do
      node = @parser.parse('dyrm u AB123 pname=foo123')
      node.command.should be_is_a UpdateCommandNode
      node.command.resource_id.text_value.should == 'AB123'

      property = node.command.property_list
      property.name.text_value.should == "pname"
      property.value.text_value.should == "foo123"
    end

    describe "Query command node" do
      it "should parse query command" do
        node = @parser.parse('q 1 beds>8', :root => 'query_command')
        node.should be_is_a QueryCommandNode
        node.layer_id.value.should == 1
        condition = node.conditional_expression
        condition.name.text_value.should == 'beds'
        condition.operator.text_value.should == '>'
        condition.value.value.should == 8
      end
    end

    describe "Update command node" do
      it "should parse update command" do
        node = @parser.parse('u AA888 foo=123, bar=bar', :root => 'update_command')
        node.should be_is_a UpdateCommandNode
        node.resource_id.text_value.should == 'AA888'
        properties = node.property_list
        first = properties.assignment_expression
        first.name.text_value.should == 'foo'
        first.value.value.should == 123

        second = properties.next
        second.name.text_value.should == 'bar'
        second.value.text_value.should == 'bar'
      end
    end

    describe "Expression nodes" do
      it "should parse conditional expression" do
        node = @parser.parse('foo>18', :root => 'conditional_expression')
        node.should be_is_a ConditionalExpressionNode
        node.name.text_value.should == 'foo'
        node.operator.text_value.should == '>'
        node.value.value.should == 18
      end

      it "should parse condition expression with spaces" do
        node = @parser.parse('name   ==   foo   ', :root => 'conditional_expression')
        node.should be_is_a ConditionalExpressionNode
        node.name.text_value.should == 'name'
        node.operator.text_value.should == '=='
        node.value.text_value.should == 'foo   '
      end

      it "should parse assignment expression" do
        node = @parser.parse('age=18', :root => 'assignment_expression')
        node.should be_is_a AssignmentExpressionNode
        node.name.text_value.should == 'age'
        node.value.value.should == 18
      end

      it "should parse assignment expression with spaces" do
        node = @parser.parse('foo  =    bar  ', :root => 'assignment_expression')
        node.should be_is_a AssignmentExpressionNode
        node.name.text_value.should == 'foo'
        node.value.text_value.should == 'bar  '
      end

      it "should parse 2 property list expression" do
        node = @parser.parse('foo=  2,     bar  =  3abc', :root => 'property_list')
        node.should_not be_nil

        first = node.assignment_expression
        first.name.text_value.should == 'foo'
        first.value.text_value.should == '2'

        second = node.next
        second.name.text_value.should == 'bar'
        second.value.text_value.should == '3abc'
      end

      pending "should not parse all property value as string"

      it "should parse unicode character" do
        node = @parser.parse('u', :root => 'character')
        node.should_not be_nil
      end

      it "should not parse symbol as character" do
        node = @parser.parse(':', :root => 'character')
        node.should be_nil
      end
    end

    describe "Elementary nodes" do
      it "should parse space" do
        node = @parser.parse(' '*5, :root => 'space')
        node.text_value.should == ' '*5
      end

      it "should parse comparison operator" do
        assert_comparison_node '>='
        assert_comparison_node '<='
        assert_comparison_node '=='
        assert_comparison_node '='
        assert_comparison_node '>'
        assert_comparison_node '<'
      end

      it "should parse number with prefix 0" do
        node = @parser.parse('0123', :root => 'number')
        node.should be_is_a NumberNode
      end

      it "should parse number 123" do
        node = @parser.parse('123', :root => 'number')
        node.should be_is_a NumberNode
      end

      pending "should parse number 5 follow by space as number"

      it "should parse symbol" do
        assert_symbol_node '.'
        assert_symbol_node '?'
        assert_symbol_node ':'
        assert_symbol_node ';'
        assert_symbol_node '-'
        assert_symbol_node '_'
        assert_symbol_node '+'
        assert_symbol_node '!'
        assert_symbol_node '@'
        assert_symbol_node '$'
        assert_symbol_node '%'
        assert_symbol_node '&'
        assert_symbol_node '*'
        assert_symbol_node '|'
        assert_symbol_node '\\'
        assert_symbol_node '/'
        assert_symbol_node '('
        assert_symbol_node ')'
        assert_symbol_node '{'
        assert_symbol_node '}'
        assert_symbol_node '['
        assert_symbol_node ']'
        assert_symbol_node '"'
        assert_symbol_node '\''
      end

      it "should parse phrase" do
        node = @parser.parse('This is a phrase.', :root => 'phrase')
        node.text_value.should == 'This is a phrase.'
      end

      it "should parse phrase with symbol in the middle and separated by space" do
        node = @parser.parse('10 - 10', :root => 'phrase')
        node.should_not be_nil
      end

      it "should parse phrase with 2 numbers separated by space" do
        node = @parser.parse('10   10', :root => 'phrase')
        node.should_not be_nil
        node.text_value.should == '10   10'
      end

      it "should parse string" do
        assert_string_node 'abc'
      end

      it "should parse string follow by number as string" do
        assert_string_node 'abc123'
      end

      it "should parse string with space" do
        assert_string_node 'test me with more text'
      end

      it "should parse string prefix by number as string" do
        assert_string_node '123abc wer'
      end

      it "should parse number by value rule" do
        node = @parser.parse('999', :root => 'value')
        node.should be_is_a NumberNode
      end

      it "should parse string with symbol as string" do
        node = @parser.parse('10--10', :root => 'word')
        node.should_not be_nil
      end

      it "should parse dyrm" do
        @parser.parse('dyrm', :root => 'dyrm').should_not be_nil
        @parser.parse('Dyrm', :root => 'dyrm').should_not be_nil
        @parser.parse('dYrm', :root => 'dyrm').should_not be_nil
        @parser.parse('dyRm', :root => 'dyrm').should_not be_nil
        @parser.parse('dyrM', :root => 'dyrm').should_not be_nil
        @parser.parse('DYRM', :root => 'dyrm').should_not be_nil
        @parser.parse('DyRM', :root => 'dyrm').should_not be_nil
      end
    end

    def assert_comparison_node(operator)
      node = @parser.parse(operator, :root => 'comparison_operator')
      node.text_value.should == operator
    end

    def assert_string_node(s)
      node = @parser.parse(s, :root => 'value')
      node.text_value.should == s
    end

    def assert_symbol_node(s)
      node = @parser.parse(s, :root => 'symbol')
      node.text_value.should == s
    end
  end
end
