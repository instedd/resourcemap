# encoding = UTF-8
require 'spec_helper'
require 'polyglot'
require File.expand_path(File.join(File.dirname(__FILE__), 'treetop_helper'))

Treetop.load 'lib/treetop/command'

describe CommandParser do
  before(:all) do
    @parser = CommandParser.new
  end

  it "should parse query command with dyrm prefix" do
    node = @parser.parse('dyrm q 1 beds>10')
    expect(node.command).to be_is_a QueryCommandNode
    expect(node.command.collection_id.value).to eq(1)

    condition = node.command.conditional_expression
    expect(condition.name.text_value).to eq('beds')
    expect(condition.operator.text_value).to eq('>')
    expect(condition.value.value).to eq(10)
  end

  it "should parse query command with dyrm prefix and '\\n' suffix" do
    node = @parser.parse("dyrm q 1 beds>10\n")
    expect(node.command).to be_is_a QueryCommandNode
  end

  it "should parse query command with dyrm prefix and space previous '\\n' suffix" do
    node = @parser.parse("dyrm q 1 beds>10 \n")
    expect(node.command).to be_is_a QueryCommandNode
  end

  it "should parse query command with dyrm prefix and '\\r' suffix" do
    node = @parser.parse("dyrm q 1 beds>10\r")
    expect(node.command).to be_is_a QueryCommandNode
  end

  it "should parse query command with dyrm prefix and space previous '\\r' suffix" do
    node = @parser.parse("dyrm q 1 beds>10 \r")
    expect(node.command).to be_is_a QueryCommandNode
  end

  it "should parse query command with dyrm prefix and '\\n\\r' suffix" do
    node = @parser.parse("dyrm q 1 beds>10\n\r")
    expect(node.command).to be_is_a QueryCommandNode
  end

  it "should parse query command with dyrm prefix and space previos '\\n\\r' suffix" do
    node = @parser.parse("dyrm q 1 beds>10\n\r")
    expect(node.command).to be_is_a QueryCommandNode
  end

  it "should parse update command with dyrm prefix" do
    node = @parser.parse('dyrm u AA111 beds=222,doctors=55')
    expect(node.command).to be_is_a UpdateCommandNode
    expect(node.command.resource_id.text_value).to eq('AA111')

    properties = node.command.property_list
    first = properties.assignment_expression
    expect(first.name.text_value).to eq("beds")
    expect(first.value.value).to eq(222)

    second = properties.next
    expect(second.name.text_value).to eq("doctors")
    expect(second.value.value).to eq(55)
  end

  it "should parse update command with dyrm prefix and 1 comma suffix" do
    node = @parser.parse("dyrm u AA111 beds=222,")
    expect(node.command).to be_is_a UpdateCommandNode
  end

  it "should parse update command with dyrm prefix and many comma suffix" do
    node = @parser.parse("dyrm u AA111 beds=222,")
    expect(node.command).to be_is_a UpdateCommandNode
  end

  it "should parse update command with dyrm prefix and '\\n' suffix" do
    node = @parser.parse("dyrm u AA111 beds=222\n")
    expect(node.command).to be_is_a UpdateCommandNode
  end

  it "should parse update command with dyrm prefix and space previous '\\n' suffix" do
    node = @parser.parse("dyrm u AA111 beds=222 \n")
    expect(node.command).to be_is_a UpdateCommandNode
  end

  it "should parse update command with dyrm prefix and '\\r' suffix" do
    node = @parser.parse("dyrm u AA111 beds=222\r")
    expect(node.command).to be_is_a UpdateCommandNode
  end

  it "should parse update command with dyrm prefix and space previous '\\r' suffix" do
    node = @parser.parse("dyrm u AA111 beds=222 \r")
    expect(node.command).to be_is_a UpdateCommandNode
  end

  it "should parse update command with dyrm prefix and '\\n\\r' suffix" do
    node = @parser.parse("dyrm u AA111 beds=222\n\r")
    expect(node.command).to be_is_a UpdateCommandNode
  end

  it "should parse update command with dyrm prefix and space previous '\\n\\r' suffix" do
    node = @parser.parse("dyrm u AA111 beds=222 \n\r")
    expect(node.command).to be_is_a UpdateCommandNode
  end

  it "should parse query command with equal condition" do
    node = @parser.parse('dyrm q 1 pname=kandal')
    expect(node.command).to be_is_a QueryCommandNode
    expect(node.command.collection_id.value).to eq(1)

    condition = node.command.conditional_expression
    expect(condition.name.text_value).to eq('pname')
    expect(condition.operator.text_value).to eq('=')
    expect(condition.value.text_value).to eq('kandal')
  end

  it "should parse update command with condition value as string" do
    node = @parser.parse('dyrm u AB123 pname=foo123')
    expect(node.command).to be_is_a UpdateCommandNode
    expect(node.command.resource_id.text_value).to eq('AB123')

    property = node.command.property_list
    expect(property.name.text_value).to eq("pname")
    expect(property.value.text_value).to eq("foo123")
  end

  describe "Query command node" do
    it "should parse query command" do
      node = @parser.parse('q 1 beds>8', :root => 'query_command')
      expect(node).to be_is_a QueryCommandNode
      expect(node.collection_id.value).to eq(1)
      condition = node.conditional_expression
      expect(condition.name.text_value).to eq('beds')
      expect(condition.operator.text_value).to eq('>')
      expect(condition.value.value).to eq(8)
    end
  end

  describe "Update command node" do
    it "should parse update command" do
      node = @parser.parse('u AA888 foo=123, bar=bar', :root => 'update_command')
      expect(node).to be_is_a UpdateCommandNode
      expect(node.resource_id.text_value).to eq('AA888')
      properties = node.property_list
      first = properties.assignment_expression
      expect(first.name.text_value).to eq('foo')
      expect(first.value.value).to eq(123)

      second = properties.next
      expect(second.name.text_value).to eq('bar')
      expect(second.value.text_value).to eq('bar')
    end
  end

  describe "Expression nodes" do
    it "should parse conditional expression" do
      node = @parser.parse('foo>18', :root => 'conditional_expression')
      expect(node).to be_is_a ConditionalExpressionNode
      expect(node.name.text_value).to eq('foo')
      expect(node.operator.text_value).to eq('>')
      expect(node.value.value).to eq(18)
    end

    it "should parse condition expression with spaces" do
      node = @parser.parse('name   ==   foo   ', :root => 'conditional_expression')
      expect(node).to be_is_a ConditionalExpressionNode
      expect(node.name.text_value).to eq('name')
      expect(node.operator.text_value).to eq('==')
      expect(node.value.text_value).to eq('foo   ')
    end

    it "should parse assignment expression" do
      node = @parser.parse('age=18', :root => 'assignment_expression')
      expect(node).to be_is_a AssignmentExpressionNode
      expect(node.name.text_value).to eq('age')
      expect(node.value.value).to eq(18)
    end

    it "should parse assignment expression with spaces" do
      node = @parser.parse('foo  =    bar  ', :root => 'assignment_expression')
      expect(node).to be_is_a AssignmentExpressionNode
      expect(node.name.text_value).to eq('foo')
      expect(node.value.text_value).to eq('bar  ')
    end

    it "should parse 2 property list expression" do
      node = @parser.parse('foo=  2,     bar  =  3abc', :root => 'property_list')
      expect(node).not_to be_nil

      first = node.assignment_expression
      expect(first.name.text_value).to eq('foo')
      expect(first.value.text_value).to eq('2')

      second = node.next
      expect(second.name.text_value).to eq('bar')
      expect(second.value.text_value).to eq('3abc')
    end

    it "should parse unicode character" do
      node = @parser.parse('u', :root => 'character')
      expect(node).not_to be_nil
    end

    it "should not parse symbol as character" do
      node = @parser.parse(':', :root => 'character')
      expect(node).to be_nil
    end
  end

  describe "Elementary nodes" do
    it "should parse space" do
      node = @parser.parse(' '*5, :root => 'space')
      expect(node.text_value).to eq(' '*5)
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
      expect(node).to be_is_a NumberNode
    end

    it "should parse number 123" do
      node = @parser.parse('123', :root => 'number')
      expect(node).to be_is_a NumberNode
    end

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
      expect(node.text_value).to eq('This is a phrase.')
    end

    it "should parse phrase with symbol in the middle and separated by space" do
      node = @parser.parse('10 - 10', :root => 'phrase')
      expect(node).not_to be_nil
    end

    it "should parse phrase with 2 numbers separated by space" do
      node = @parser.parse('10   10', :root => 'phrase')
      expect(node).not_to be_nil
      expect(node.text_value).to eq('10   10')
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
      expect(node).to be_is_a NumberNode
    end

    it "should parse string with symbol as string" do
      node = @parser.parse('10--10', :root => 'word')
      expect(node).not_to be_nil
    end

    it "should parse dyrm" do
      expect(@parser.parse('dyrm', :root => 'dyrm')).not_to be_nil
      expect(@parser.parse('Dyrm', :root => 'dyrm')).not_to be_nil
      expect(@parser.parse('dYrm', :root => 'dyrm')).not_to be_nil
      expect(@parser.parse('dyRm', :root => 'dyrm')).not_to be_nil
      expect(@parser.parse('dyrM', :root => 'dyrm')).not_to be_nil
      expect(@parser.parse('DYRM', :root => 'dyrm')).not_to be_nil
      expect(@parser.parse('DyRM', :root => 'dyrm')).not_to be_nil
    end
  end

  def assert_comparison_node(operator)
    node = @parser.parse(operator, :root => 'comparison_operator')
    expect(node.text_value).to eq(operator)
  end

  def assert_string_node(s)
    node = @parser.parse(s, :root => 'value')
    expect(node.text_value).to eq(s)
  end

  def assert_symbol_node(s)
    node = @parser.parse(s, :root => 'symbol')
    expect(node.text_value).to eq(s)
  end
end
