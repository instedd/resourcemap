class HashParser
  def self.from_xml_file(xml)
    raise "missing xml file" if xml.nil?
    begin
      submission = Hash.from_xml(xml.read)
    rescue 
      raise "invalid xml format" 
    end
  end
end
