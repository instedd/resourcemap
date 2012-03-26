class Search
  class << self
    attr_accessor :page_size
  end
  Search.page_size = 50

  def initialize(collection)
    @collection = collection
    @search = collection.new_tire_search
    @search.size self.class.page_size
    @from = 0
  end

  def page(page)
    @search.from((page - 1) * self.class.page_size)
    self
  end

  def id(id)
    @search.filter :term, id: id
    self
  end

  def eq(property, value)
    @search.filter :term, Site.encode_elastic_search_keyword(property) => value
    self
  end

  ['lt', 'lte', 'gt', 'gte'].each do |op|
    class_eval %Q(
      def #{op}(property, value)
        @search.filter :range, Site.encode_elastic_search_keyword(property) => {#{op}: value}
        self
      end
    )
  end

  def op(property, op, value)
    case op.to_s.downcase
    when '<', 'l' then lt(property, value)
    when '<=', 'lte' then lte(property, value)
    when '>', 'gt' then gt(property, value)
    when '>=', 'gte' then gte(property, value)
    when '=', '==', 'eq' then eq(property, value)
    else raise "Invalid operation: #{op}"
    end
    self
  end

  def where(properties = {})
    properties.each do |property, value|
      if value.is_a? String
        case
        when value[0 .. 1] == '<=' then lte(property, value[2 .. -1].strip)
        when value[0] == '<' then lt(property, value[1 .. -1].strip)
        when value[0 .. 1] == '>=' then gte(property, value[2 .. -1].strip)
        when value[0] == '>' then gt(property, value[1 .. -1].strip)
        when value[0] == '=' then eq(property, value[1 .. -1].strip)
        else eq(property, value)
        end
      else
        eq(property, value)
      end
    end
    self
  end

  def before(time)
    time = Time.parse time if time.is_a? String
    @search.filter :range, updated_at: {lte: Site.format_date(time)}
    self
  end

  def after(time)
    time = Time.parse time if time.is_a? String
    @search.filter :range, updated_at: {gte: Site.format_date(time)}
    self
  end

  def in_group(site)
    site = Site.find(site) unless site.is_a? Site
    parent_ids = (site.hierarchy || '').split(',').map(&:to_i)
    parent_ids << site.id
    parent_ids.each do |parent_id|
      @search.filter :term, parent_ids: parent_id
    end
    self
  end

  def full_text_search(text)
    codes = search_value_codes text
    codes << text
    @search.query { string "#{codes.join ' '}*" }
    self
  end

  def results
    @search.sort { by '_uid' }
    decode_elastic_search_results @search.perform.results
  end

  private

  def decode_elastic_search_results(results)
    results.each do |result|
      result['_source']['properties'] = Site.decode_elastic_search_keywords(result['_source']['properties'])
    end
    results
  end

  def search_value_codes(text)
    @fields ||= @collection.fields.all.select{|x| x.kind == 'select_one' || x.kind == 'select_many'}

    codes = []
    regex = /#{text}/i
    @fields.each do |field|
      field.config['options'].each do |option|
        if option['label'] =~ regex
          codes << option['code']
        end
      end
    end
    codes
  end
end
