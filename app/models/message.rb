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
end
