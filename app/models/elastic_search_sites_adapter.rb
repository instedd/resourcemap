class ElasticSearchSitesAdapter < Psych::Handler
  def initialize(listener)
    @listener = listener
    @source_mappings = 0
    @properties_mappings = 0
    @parent_ids = []
  end

  def parse(reader)
    Psych::Parser.new(self).parse reader
  end

  def scalar(value, anchor, tag, plain, quoted, style)
    if value == '_source'
      @in_source = true
      @parent_ids.clear
    elsif @in_source
      return if @in_properties

      if @current_property
        case @current_property
        when 'id' then @id = value.to_i
        when 'lat' then @lat = value.to_f
        when 'lon' then @lng = value.to_f
        end
        @current_property = nil
      else
        if @in_parent_ids
          @parent_ids << value.to_i
        else
          case value
          when 'properties' then @in_properties = true
          when 'parent_ids' then @in_parent_ids = true
          else @current_property = value
          end
        end
      end
    end
  end

  def start_mapping(anchor, tag, implicit, style)
    if @in_source
      @source_mappings += 1
      @current_property = nil
      if @in_properties
        @properties_mappings += 1
      end
    end
  end

  def end_mapping
    if @in_source
      @source_mappings -= 1
      if @source_mappings == 0
        @in_source = false
        @listener.add @id, @lat, @lng, @parent_ids
      end

      if @in_properties
        @properties_mappings -= 1
        @in_properties = false if @properties_mappings == 0
      end

      if @in_parent_ids
        @in_parent_ids = false
      end
    end
  end
end
