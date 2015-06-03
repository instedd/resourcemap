class ChangeFieldConfigSerializationToMsgpack < ActiveRecord::Migration
  def up
    connection.select_rows("SELECT id, config FROM fields").each do |id, config|

      next if config.blank?
      begin
        config = MarshalZipSerializable.load(config)
      rescue Exception => ex
        next
      end

      new_config = MsgpackZipSerializable.dump(config)
      if new_config.nil?
        connection.execute("UPDATE fields SET config=NULL WHERE id=#{id}")
      else
        connection.execute("UPDATE fields SET config=x'#{new_config.unpack("H*")[0]}' WHERE id=#{id}")
      end
    end
  end

  def down
    connection.select_rows("SELECT id, config FROM fields").each do |id, new_config|
      next if new_config.blank?

      config = MsgpackZipSerializable.load(new_config)
      config = MarshalZipSerializable.dump(config)

      if config.nil?
        connection.execute("UPDATE fields SET config=NULL WHERE id=#{id}")
      else
        connection.execute("UPDATE fields SET config=x'#{config.unpack("H*")[0]}' WHERE id=#{id}")
      end
    end
  end
end
