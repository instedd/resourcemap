Tire::Configuration.wrapper Hash

class Tire::Search::Search
  def stream
    uri = URI(url)
    reader, writer = IO.pipe
    producer = Thread.new(writer) do |io|
      Net::HTTP.start(uri.host, uri.port) do |http|
        request = Net::HTTP::Get.new uri.request_uri
        http.request request, to_json do |response|
          response.read_body { |segment| io.write segment }
        end
        io.close
      end
    end
    reader
  end
end

class Tire::Index
  def update_mapping(mapping)
    mapping.each do |type, value|
      url, body = "#{Tire::Configuration.url}/#{@name}/#{type}/_mapping", MultiJson.encode(type => value)
      begin
        @response = Tire::Configuration.client.put url, body
        raise RuntimeError, "#{@response.code} > #{@response.body}" if @response.failure?
      ensure
        curl = %Q|curl -X PUT "#{url}" -d '#{body}'|
        logged('MAPPING', curl)
      end
    end
    true
  end
end

module Tire
  def self.delete_indices_that_match(regex)
    indexes = JSON.parse Tire::Configuration.client.get("#{Tire::Configuration.url}/_status").body
    indexes['indices'].each do |name, index|
      Tire::Index.new(name).delete if name =~ regex
    end
  end
end
