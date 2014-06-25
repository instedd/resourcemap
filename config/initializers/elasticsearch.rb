Tire::Configuration.wrapper Hash

# prefix method exists in Tire since revision 995ea29,
# but wasn't released to the public at the time of this writing.
class Tire::Search::Query
  def prefix(field, value, options={})
    if options[:boost]
      @value = { :prefix => { field => { :prefix => value, :boost => options[:boost] } } }
    else
      @value = { :prefix => { field => value } }
    end
  end
end

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

module Tire
  class Index
    # Fix: suppor the 'refresh' option in store.
    # We could use this branch: https://github.com/ahey/retire/commit/b8b100f2b3eef9a49d0dc22ee40594bdf1adb777
    # But this way is more independent and robust.
    def store(*args)
      document, options = args

      id       = get_id_from_document(document)
      type     = get_type_from_document(document)
      document = convert_document_to_json(document)

      options ||= {}
      params    = {}

      if options[:percolate]
        params[:percolate] = options[:percolate]
        params[:percolate] = "*" if params[:percolate] === true
      end

      params[:parent]  = options[:parent]  if options[:parent]
      params[:routing] = options[:routing] if options[:routing]
      params[:replication] = options[:replication] if options[:replication]
      params[:version] = options[:version] if options[:version]
      params[:refresh] = options[:refresh] if options[:refresh]

      params_encoded = params.empty? ? '' : "?#{params.to_param}"

      url  = id ? "#{self.url}/#{type}/#{Utils.escape(id)}#{params_encoded}" : "#{self.url}/#{type}/#{params_encoded}"

      @response = Configuration.client.post url, document
      MultiJson.decode(@response.body)
    ensure
      curl = %Q|curl -X POST "#{url}" -d '#{document}'|
      logged([type, id].join('/'), curl)
    end
  end
end
