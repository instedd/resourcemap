class ElasticSearchSitesAdapter < Psych::Handler
  def initialize(listener)
    @listener = listener
    @mappings = 0
  end

  def parse(reader)
    Psych::Parser.new(self).parse reader
  end

  def scalar(value, anchor, tag, plain, quoted, style)
    if value == '_source'
      @in_source = true
    elsif @in_source
      if @current_property
        case @current_property
        when 'id' then @id = value.to_i
        when 'lat' then @lat = value.to_f
        when 'lon' then @lng = value.to_f
        end
        @current_property = nil
      else
        @current_property = value
      end
    end
  end

  def start_mapping(anchor, tag, implicit, style)
    if @in_source
      @mappings += 1
      @current_property = nil
    end
  end

  def end_mapping
    if @in_source
      @mappings -= 1
      if @mappings == 0
        @in_source = false
        @listener.add @id, @lat, @lng
      end
    end
  end
end
