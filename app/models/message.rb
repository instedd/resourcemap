class Message < ActiveRecord::Base
  validates_presence_of :body, :from
  validates_presence_of :guid, :unless => :is_send
  INVALID_COMMAND = "Invalid command"
  belongs_to :collection  
  after_create :update_message_quota

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

  def self.log nuntium_messages, collection_id
    nuntium_messages.each do |ns|
      message = Message.new from: ns[:from], to: ns[:to], body: ns[:body], channel: ns[:suggested_channel], is_send: true, collection_id: collection_id
      message.save!
    end
    #c = Collection.find collection_id
    #c.quota = c.quota - nuntium_messages.length
    #c.save!
  end

  def update_message_quota
    return unless is_send 
    c = Collection.find collection_id 
    c.quota = c.quota - 1
    c.save!
  end
end
