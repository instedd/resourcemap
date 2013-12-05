xml = Builder::XmlMarkup.new(:encoding => 'utf-8', :escape => false)
xml.soap(:Envelope, {"xmlns:soap" => "http://schemas.xmlsoap.org/soap/envelope/" } ) do
  xml.soap :Body do
    xml.soap :Fault do
      xml.tag!("faultcode") do
        xml.text!("soap:#{@fault_code}")
      end
      xml.tag!("faultstring") do
         xml.text!("#{@fault_string}")
      end
    end
  end
end
