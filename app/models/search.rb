class Search
  def initialize(collection_id)
    @search = Collection.new_tire_search(collection_id)
  end

  def eq(property, value)
    @search.filter :term, property => value
    self
  end

  ['lt', 'lte', 'gt', 'gte'].each do |op|
    class_eval %Q(
      def #{op}(property, value)
        @search.filter :range, property => {#{op}: value}
      end
    )
  end

  def op(op, property, value)
    case op.to_s.downcase
    when '<', 'l' then lt(property, value)
    when '<=', 'lte' then lte(property, value)
    when '>', 'gt' then gt(property, value)
    when '>=', 'gte' then gte(property, value)
    when '=', '==', 'eq' then eq(property, value)
    else raise "Invalid operation: #{op}"
    end
  end

  def where(properties = {})
    properties.each { |property, value| eq(property, value) }
    self
  end

  def results
    @search.perform.results
  end
end
