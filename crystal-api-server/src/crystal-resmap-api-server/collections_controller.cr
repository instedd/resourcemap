require "http"

class CollectionsController
  property! context

  def params
    context["params"] as Hash(String, JSON::Type)
  end

  def visible_field_ids
    (context["visible_field_ids"] as Array(JSON::Type)).map { |x| x as Int64 }.to_a
  end

  def show(collection_id)
    collection = Collection.find(collection_id, visible_field_ids)

    client = HTTP::Client.new("localhost", 9200)

    post_body = String::Builder.new
    post_body.json_object do |obj|
      obj.field "filter" do
        post_body.json_object do |obj|
          obj.field "terms" do

            post_body.json_object do |obj|

              params.each do |k, v|
                # filter by {{field_code}}[under] = {{id}}
                # if k =~ /(.*)\[under\]/

                  f = collection.field_by_code(k)
                  if v.is_a?(Hash) && v.has_key?("under")
                    p = f.find_hierarchy_node(v["under"])

                    obj.field(f.id) do
                      post_body.json_array do |arr|
                        f.hierarchy_descendants(p) do |node|
                          arr << node["id"]
                        end
                      end
                    end
                  end

                # end
              end

            end


          end
        end
      end
      obj.field "sort", "name.downcase"
      obj.field "size", 1000000
    end

    response = client.get "collection_#{collection_id}/site/_search?pretty", nil, post_body.to_s

    result_sites = Array(JSON::Type).new
    Site.translate(collection, response) do |api_site|
      result_sites << api_site
    end

    result = Hash(String, JSON::Type).new
    result["name"] = collection.name
    result["count"] = result_sites.size.to_i64
    result["totalPages"] = nil
    result["sites"] = result_sites

    puts result.to_json
  end
end
