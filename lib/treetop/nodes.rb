class CommandNode < Treetop::Runtime::SyntaxNode
	attr_accessor :sender
	
	def set_reply_text(value)
		@reply_text = value
	end
	
	def reply_text
		@reply_text
	end
end

class QueryCommandNode < CommandNode
	# :condition
	def accept(visitor)
		visitor.visit_query_command self
	end
end

class UpdateCommandNode < CommandNode
	# :resource_id
	# :property_list
	def accept(visitor)
		visitor.visit_update_command self
	end
end

class ConditionalExpressionNode < Treetop::Runtime::SyntaxNode
	# :string
	# :comparison_operator
	# :value
	def to_options
		{
			:code => self.name.text_value,
			:operator => self.operator.text_value,
			:value => self.value.text_value
		}
	end
end

class AssignmentExpressionNode < Treetop::Runtime::SyntaxNode
	# :string
	# :value
	def to_options
		{
			:code => self.name.text_value,
			:value => self.value.text_value
		}
	end
end

class NumberNode < Treetop::Runtime::SyntaxNode
	def value
		text_value.to_i
	end
end
