xml.SOAP(:Envelope, "xmlns:SOAP" => "http://schemas.xmlsoap.org/soap/envelope/") do
  xml.SOAP :Body do
    xml.SOAP :Fault do
      xml.faultcode "SOAP:#{@fault_code}"
      xml.faultstring @fault_string
    end
  end
end
