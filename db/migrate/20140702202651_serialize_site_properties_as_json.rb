class SerializeSitePropertiesAsJson < ActiveRecord::Migration
  class Site < ActiveRecord::Base
  end

  TABLE_NAMES = %w(sites site_histories)

  def up
    TABLE_NAMES.each do |table_name|
      convert_properties table_name, YAML, JSON
    end
  end

  def down
    TABLE_NAMES.each do |table_name|
      convert_properties table_name, JSON, YAML
    end
  end

  def convert_properties(table_name, from, to)
    results = execute("select id, properties from #{table_name}")
    results.each do |id, properties|
      if properties
        begin
          original = from.load properties
          converted = to.dump original
          converted = converted.dump
          # converted = connection.quote(converted)
          execute("update #{table_name} set properties = #{converted} where id = #{id}")
        rescue Exception => ex
          binding.pry
          raise ex
        end
      end
    end
  end
end
