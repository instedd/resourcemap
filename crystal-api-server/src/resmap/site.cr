require "json"
require "../shims/*"

class Site

  def self.api_time(value)
    # Optimization for when the string has 24 chars, which should
    # be something like this: 20140522T063835.000+0000
    # This is the format we store datetimes in Elasticsearch, so
    # the `else` part of the if shouldn't execute, but just in case...
    year = value[0, 4].to_i
    month = value[4, 2].to_i
    day = value[6, 2].to_i
    hour = value[9, 2].to_i
    minute = value[11, 2].to_i
    second = value[13, 2].to_i
    offset = value[19 .. -1].to_i
    time = Time.new(year, month, day, hour, minute, second, offset)

    time.to_s("%FT%T.%L#{offset == 0 ? 'Z' : raise "not implementend"}")
  end

  def self.api_date(value)
    Time.parse(value, "%F").to_s("%d/%m/%Y")
  end

  def self.translate(collection, elasticsearch_response, output)
    output.json_object do |root|
      root.field "name", collection.name
      root.field "totalPages", nil

      pull = JSON::PullParser.new(elasticsearch_response.body)

      pull.on_key("hits") do
        pull.read_object do |hit_field_key|
          case hit_field_key
          when "total"
            root.field "count", pull.read_int
          when "hits"
            root.field "sites" do
              output.json_array do |sites_output|

                pull.read_array do
                  pull.on_key("_source") do

                    # TODO should not be needed. if JSON::ArrayBuilder will allow to write elements from JSON::ObjectBuilder
                    api_site = Hash(String, JSON::Type).new

                    pull.read_object do |key|
                      # puts key
                      case key
                      when "id"
                        api_site["id"] = pull.read_int
                      when "name"
                        api_site["name"] = pull.read_string
                      when "created_at"
                        api_site["createdAt"] = api_time(pull.read_string)
                      when "updated_at"
                        api_site["updatedAt"] = api_time(pull.read_string)
                      when "location"
                        pull.read_object do |key|
                          case key
                          when "lat"
                            api_site["lat"] = pull.read_float
                          when "lon"
                            api_site["long"] = pull.read_float
                          else
                            pull.skip
                          end
                        end
                      when "properties"
                        props = api_site["properties"] = Hash(String, JSON::Type).new

                        pull.read_object do |field_key|
                          f = collection.field_by_id(field_key.to_i)
                          if f
                            props[f.code.not_nil!] = case f.kind
                            when "numeric"
                              pull.read_float
                            when "select_one"
                              v = pull.read_int
                              f.config_options_value_for_id(v)
                            when "hierarchy", "identifier", "text", "email", "phone"
                              pull.read_string
                            when "date"
                              api_date(pull.read_string)
                            when "select_many"
                              a = [] of JSON::Type
                              pull.read_array do
                                a << f.config_options_value_for_id(pull.read_int)
                              end
                              a
                            else
                              raise "Not implementend #{f.kind}"
                            end
                          else
                            pull.skip
                          end
                        end
                      else
                        pull.skip
                      end
                    end

                    sites_output << api_site
                  end
                end
              end
            end
          else
            pull.skip
          end
        end
      end
    end
  end
end
