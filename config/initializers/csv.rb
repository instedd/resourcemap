require 'csv'

# Try to parse the file using utf-8 encoding.
# If it's not valid, we assume it's latin1 (Windows default)
module CSV_InitializeWithEncoding
  def new(data, options = {})
    options[:encoding] ||= 'utf-8'
    begin
      super data, options
    rescue => ex
      options[:encoding] = 'ISO-8859-1:utf-8'
      data.rewind if data.respond_to? :rewind
      super data, options
    end
  end

  def open(*args, &block)
    options = if args.last.is_a? Hash then args.pop else Hash.new end
    options[:encoding] ||= 'utf-8'

    begin
      super *(args + [options]), &block
    rescue
      options[:encoding] = 'ISO-8859-1:utf-8'
      super *(args + [options]), &block
    end
  end
end

# Patch CSV class to try to open the file with the correct encoding.
class CSV
  class << self
    prepend CSV_InitializeWithEncoding
  end
end
