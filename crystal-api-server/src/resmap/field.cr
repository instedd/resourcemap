require "./serializer"

class Field
  property id, name, code, kind
  property config :: Hash(MessagePack::Type, MessagePack::Type) | Nil

  def initialize
    @config = nil
  end

  def config
    @config.not_nil!
  end

  def config_options_value_for_id(id)
    o = config["options"]
    if o.is_a?(Array)
      option_for_id = o.select { |i| (i as Hash)["id"] == id }.first as Hash
      option_for_id["code"].to_s
    else
      raise "config options is not an array"
    end
  end

  def config_hierarchy
    config["hierarchy"] as Array(MessagePack::Type)
  end

  def api_value(value)
    value
  end

  def self.where(filters)
    sql = String::Builder.build do |builder|
      builder << "SELECT id, name, code, kind, config FROM fields WHERE 1=1 "

      filters.each do |k, v|
        if v.is_a?(Array)
          builder << "AND #{k} IN (#{v.join(", ")}) "
        else
          builder << "AND #{k}=#{v} "
        end
      end
    end

    fields = [] of Field
    Database.instance.execute(sql).each_row do |row|
      fields << init_from_row(row)
    end

    fields
  end

  def self.init_from_row(row)
    field = self.new
    field.id = row[0] as Int32
    field.name = row[1] as String
    field.code = row[2] as String
    field.kind = row[3] as String

    config_array = row[4] as Array(UInt8) | Nil
    field.config = if config_array
      Serializer::Msgpack.deserialize(Serializer::Gzip.deserialize(Slice.new(config_array.buffer, config_array.size))) as Hash(MessagePack::Type, MessagePack::Type)
    else
      nil
    end

    field
  end

  def find_hierarchy_node(id)
    iterate_hierarchy_nodes(config_hierarchy) do |node|
      return node if node["id"] == id
    end

    raise "hierarchy node not found"
  end

  def hierarchy_descendants(hierarchy_node)
    self.iterate_hierarchy_nodes([hierarchy_node]) do |node|
      yield node
    end
  end

  def iterate_hierarchy_nodes(nodes)
    pending = nodes.clone
    while !pending.empty?
      n = pending.pop #as Hash(MessagePack::Type, Array(MessagePack::Type))
      if n.is_a?(Hash(MessagePack::Type, MessagePack::Type))
        sub = n["sub"]?

        if sub.is_a?(Array(MessagePack::Type))
          sub.each do |sub_node|
            pending.push sub_node as Hash(MessagePack::Type, MessagePack::Type)
          end
        end

        yield n
      end
    end
  end
end
