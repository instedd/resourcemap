module Membership::LayerAccessConcern
  extend ActiveSupport::Concern

  def set_layer_access(options = {})
    read =  options[:verb].to_s == 'read' ? options[:access] : nil
    write = options[:verb].to_s == 'write' ? options[:access] : nil

    lm = layer_memberships.where(:layer_id => options[:layer_id]).first
    if lm
      lm.read = read unless read.nil?
      lm.write = write unless write.nil?
      if lm.read || lm.write
        lm.save!
      else
        lm.destroy
      end
    else
      layer_memberships.create! :layer_id => options[:layer_id], :read => read, :write => write
    end
  end

end
