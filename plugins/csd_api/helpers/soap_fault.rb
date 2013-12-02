module SoapFault
  class ClientError < StandardError
    def fault_code
      "Client"
    end
  end

  class MustUnderstandError < StandardError
    def fault_code
      "MustUnderstand"
    end
  end
end
