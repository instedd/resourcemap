module Field::FredApiConcern
  extend ActiveSupport::Concern

  # metadata: {"0"=>{"key"=>"context", "value"=>"MOH"}, "1"=>{"key"=>"agency", "value"=>"DHIS"}}

  def identifier?
    metadata && metadata.any?{|index, element| element["key"] == "agency"} && metadata.any?{|index, element| element["key"] == "context"}
  end

  def context
    metadata.select{|i, e| e["key"] == "context"}.values[0]["value"]
  end

  def agency
    metadata.select{|i, e| e["key"] == "agency"}.values[0]["value"]
  end

end
