class ExecVisitor < Visitor
  MSG = {
    :query_not_match => "No result. Your query did not match.",
    :update_successfully => "Data has been successfully updated.",
    :can_not_update => "You have no access right to update. Please contact the layer's owner for more information.",
    :can_not_query => "You have no access right to view. Please contact the layer's owner for more information.",
    :can_not_use_gateway => "You cannot use this channel for viewing or updating this layer. Please contact the layer's owner for more information."
  }

  attr_accessor :context

  def initialize(context={})
    self.context = context
  end
  
  def visit_query_command(node)
    if layer = Layer.find_by_id(node.layer_id.value)
      raise MSG[:can_not_use_gateway] unless can_use_gateway?(layer)
      raise MSG[:can_not_query]       unless can_view?(node.sender, layer)
      
      if reply = layer.query_resources(node.conditional_expression.to_options)
        reply.empty? ? MSG[:query_not_match] : reply
      end
    end
  end

  def visit_update_command(node)
    id = node.resource_id.text_value
    if site = Site.find_by_id_with_prefix(id)
      #raise MSG[:can_not_use_gateway] unless can_use_gateway?(resource.layer)
      #raise MSG[:can_not_update]      unless can_update?(node.sender, resource)

      update site, node.property_list, node.sender
      MSG[:update_successfully]
    else
      raise "Can't find resource with ID=#{id}" if site.nil?
    end
  end

  def can_use_gateway?(layer)
    gateway = Gateway.find_by_nuntium_name(self.context[:channel])
    gateway.nil? || gateway.allows_layer?(layer)
  end

  def can_view?(sender, layer)
    sender && sender.can_view?(layer)
  end

  def can_update?(sender, resource)
    sender && sender.can_update?(resource)
  end

  private
  
  def update(resource, node, sender)
		properties = []

		until node and node.kind_of? AssignmentExpressionNode
      properties << node.assignment_expression.to_options
      node = node.next
    end
    properties << node.to_options
		resource.update_properties sender, properties
  end

end
