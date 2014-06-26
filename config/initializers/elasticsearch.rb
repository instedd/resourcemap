Tire::Configuration.wrapper Hash

class Tire::Search::Search
  def stream
    uri = URI(url)
    reader, writer = IO.pipe
    producer = Thread.new(writer) do |io|
      begin
        Net::HTTP.start(uri.host, uri.port) do |http|
          request = Net::HTTP::Get.new uri.request_uri
          http.request request, to_json do |response|
            response.read_body { |segment| io.write segment.dup.force_encoding("UTF-8") }
          end
        end
      rescue Exception => ex
        Rails.logger.error ex.message + "\n" + ex.backtrace.join("\n")
      ensure
        io.close
      end
    end
    reader
  end
end
