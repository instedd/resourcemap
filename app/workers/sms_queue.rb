class SmsQueue
  @queue = :sms_queue
  def self.perform threshold
    
    @from = "85512220270" 
    @to   = "nuntium"
    @body = "it just the first test"
    
    nuntium = Nuntium.new_from_config
    nuntium.send_ao(:from => @from, :to => "sms://#{@to}", :body => @body)
  end
end
