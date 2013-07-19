class SerializeExistingFieldsConfig < ActiveRecord::Migration
  def up
    connection.select_rows("SELECT id, config FROM fields").each do |id, config|

      next if config.blank?
      begin
        config = YAML.load(config)
      rescue Exception => ex
        begin
         config.force_encoding "iso8859-1"
          config = YAML.load(config)
        rescue Exception => ex2
          next
        end
      end

      binary_config = MarshalZipSerializable.dump(config)
      if binary_config.nil?
        connection.execute("UPDATE fields SET config=NULL WHERE id=#{id}")
      else
        connection.execute("UPDATE fields SET config=x'#{binary_config.unpack("H*")[0]}' WHERE id=#{id}")
      end
    end
  end

  def down
    connection.select_rows("SELECT id, config FROM fields").each do |id, binary_config|
      next if binary_config.blank?

      config = MarshalZipSerializable.load(config)
      config = YAML.dump(config)
      config = ActiveRecord::Base.send(:sanitize_sql_for_assignment, :config => config)

      connection.execute("UPDATE fields SET #{config} WHERE id=#{id}")
    end
  end
end
