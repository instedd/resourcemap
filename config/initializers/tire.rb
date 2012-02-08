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
