class Message < ActiveRecord::Base
  validates_presence_of :guid, :body, :from
  
  INVALID_COMMAND = "Invalid command"
  
  def process!(context=nil)
  	self.reply = visit(parse.command, context)
  end
  
  def parse
  	CommandParser.new.parse(self.body) or raise INVALID_COMMAND
  end
  
  def visit(command, context)
    command.sender = self.sender
  	command.accept ExecVisitor.new(context)
  end

  def sender
    if channel?(:sms)
			User.find_by_phone_number(self.from[6..-1]) || User.find_by_phone_number("+" + self.from[6..-1])
		end
  end

  def channel?(protocol)
    self.from && self.from.start_with?("#{protocol.to_s}://")
  end

  def self.getCollectionId(bodyMsg, start)
    k = 1
    for j in (1..bodyMsg.length)
    if (bodyMsg[start+k] != " ")
      k = k+1
      else
        return bodyMsg[start..start+(k-1)]
        break
      end
    end
  end

  def self.generateLayerMessagingByLayerId(layer_id, year)
    layerReport = []
    month = []
    month = [1,2,3,4,5,6,7,8,9,10,11,12]
    for i in (0..(month.length-1))
      countMsg = Message.where("date_format(created_at, '%Y') = ? and date_format(created_at, '%m') = ? and layer_id = ?", year,month[i],layer_id).count
      message = {
        "month" => month[i],
        "count" => countMsg
        }
      layerReport.push(message)
    end
    return layerReport
  end
end
