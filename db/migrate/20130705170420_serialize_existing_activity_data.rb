class SerializeExistingActivityData < ActiveRecord::Migration
  def up
    connection.select_rows("SELECT id, data FROM activities").each do |id, data|

      next if data.blank?
      begin
        data = YAML.load(data)
      rescue Exception => ex
        begin
         data.force_encoding "iso8859-1"
         data = YAML.load(data)
        rescue Exception => ex2
          next
        end
      end

      binary_data = MarshalZipSerializable.dump(data)
      if binary_data.nil?
        connection.execute("UPDATE activities SET data=NULL WHERE id=#{id}")
      else
        connection.execute("UPDATE activities SET data=x'#{binary_data.unpack("H*")[0]}' WHERE id=#{id}")
      end
    end
  end

  def down
    connection.select_rows("SELECT id, data FROM activities").each do |id, binary_data|
      next if binary_data.blank?

      data = MarshalZipSerializable.load(data)
      data = YAML.dump(data)
      data = ActiveRecord::Base.send(:sanitize_sql_for_assignment, :data => data)

      connection.execute("UPDATE activities SET #{data} WHERE id=#{id}")
    end
  end
end
