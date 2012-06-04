class ElasticSearch::SitesAdapter < Psych::Handler
  def initialize(listener)
    @listener = listener
    @source_mappings = 0
    @properties_mappings = 0
    @site = {}
  end

  def parse(reader)
    Psych::Parser.new(self).parse reader
  end

  def scalar(value, anchor, tag, plain, quoted, style)
    if value == '_source'
      @in_source = true
    elsif value == '_index'
      @in_index = true
    elsif @in_index
      value =~ /(\d+)/
      @site[:collection_id] = $1.to_i
      @in_index = false
    elsif @in_source
      return if @in_properties
      if @current_property
        case @current_property
        when 'id' then @site[:id] = value.to_i
        when 'lat' then @site[:lat] = value.to_f
        when 'lon' then @site[:lng] = value.to_f
        when 'name' then @site[:name] = value.to_s
        end
        @current_property = nil
      else
        case value
        when 'properties' then @in_properties = true
        else @current_property = value
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
        @listener.add @site
      end

      if @in_properties
        @properties_mappings -= 1
        @in_properties = false if @properties_mappings == 0
      end
    end
  end

  class SkipIdListener
    def initialize(listener, id)
      @listener = listener
      @excluded_id = id
    end

    def add(site)
      @listener.add site if @excluded_id != site[:id]
    end
  end
end
