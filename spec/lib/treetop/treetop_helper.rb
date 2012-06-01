require 'treetop_dependencies'
## To pre-compile grammar file in test
#Treetop.load File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'lib', 'treetop', 'command'))

module PropertyAssertionHelper
	def assert_property(name, value, node)
		property = defined?(node.assignment_expression)? node.assignment_expression : node
		property.name.text_value == name
		property.value.value == value
	end
end

