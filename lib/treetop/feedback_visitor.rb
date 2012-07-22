class FeedbackVisitor < Visitor
	def visit_query_command(node)
#		if node.reply_text
#	  	response.headers['X-GeoChat-Action'] = 'reply'
#	  	render :text => node.reply_text
#	  else
#	  	response.headers['X-GeoChat-Action'] = 'stop'
#	  	head :ok
#	  end
	end
	
	def visit_update_command(node)
		msg = <<-MSG
You send an sms update for:
  - Resource: "#{node.resource_id.value}"
  - Properties: 
MSG
		current = node.property_list
		until current.kind_of? AssignmentExpressionNode
			assignment_expression = current.assignment_expression
			msg << "    - " << assignment_expression.name.text_value << "=" << assignment_expression.value.text_value << "\n"
			current = current.next
		end
		msg << "    - " << current.name.text_value << "=" << current.value.text_value << "\n"
		
		node.reply_text = msg
	end
end
