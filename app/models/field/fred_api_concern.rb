module Field::FredApiConcern
  extend ActiveSupport::Concern

  # metadata: {"0"=>{"key"=>"context", "value"=>"MOH"}, "1"=>{"key"=>"agency", "value"=>"DHIS"}}

  def identifier?
    metadata && metadata.any?{|index, element| element["key"].downcase == "agency"} && metadata.any?{|index, element| element["key"].downcase == "context"}
  end

  def context
    metadata.select{|i, e| e["key"].downcase == "context"}.values[0]["value"]
  end

  def agency
    metadata.select{|i, e| e["key"].downcase == "agency"}.values[0]["value"]
  end

end
