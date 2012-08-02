class ElasticSearch::SitesAdapter < Psych::Handler
  IGNORE_FIELDS = %w(type created_at updated_at)

  def initialize(listener)
    @listener = listener
    @source_mappings = 0
    @properties_mappings = 0
    @site = {}
    @site[:property] = []
  end

  def parse(reader)
    Psych::Parser.new(self).parse reader
  end

  def return_property(property)
    @return_property = property
    @site[:property] = []
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
      if @in_properties
        return unless @return_property
        if @current_property
          if @current_property == @return_property
             @site[:property] << value.to_s
          end
          @current_property = nil if !@in_sequence
        else
          @current_property = value
        end
      else
        if @current_property
          case @current_property
          when 'id' then @site[:id] = value.to_i
          when 'lat' then @site[:lat] = value.to_f
          when 'lon' then @site[:lng] = value.to_f
          when 'name' then @site[:name] = value.to_s
          else
            @site[@current_property.to_sym] = value.to_s unless IGNORE_FIELDS.include? @current_property
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
  end

  def start_sequence(anchor, tag, implicit, style)
    if  @return_property && @current_property == @return_property
      @in_sequence = true
      @site[:property] = []
    end
  end

  def end_sequence
    @current_property = nil
     @in_sequence = false
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
        @site[:property] = []
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
