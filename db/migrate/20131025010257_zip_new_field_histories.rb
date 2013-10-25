class ZipNewFieldHistories < ActiveRecord::Migration
  def up
    FieldHistory.connection.select_rows("SELECT id, config FROM field_histories").each do |id, binary_config|
      next if binary_config.blank?

      begin
        MarshalZipSerializable.load(binary_config)
      rescue
        puts "Binary config in field_history with ID=#{id} is invalid."
        begin
          config = YAML.load(binary_config)
          new_binary_value = MarshalZipSerializable.dump(config)
          if new_binary_value.nil?
            FieldHistory.connection.execute("UPDATE field_histories SET config=NULL WHERE id=#{id}")
          else
            FieldHistory.connection.execute("UPDATE field_histories SET config=x'#{new_binary_value.unpack("H*")[0]}' WHERE id=#{id}")
          end
          puts "Value updated!"
        rescue Exception => ex
          puts "It cannot be ziped. The problematic config is #{binary_config}"
          puts ex.message
        end
      end

    end
  end
end
