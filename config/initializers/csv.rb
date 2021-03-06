require 'csv'

# Patch CSV class to try to open the file with the correct encoding.
class CSV

  def initialize_with_encoding(data, options = {})
    # Try to parse the file using utf-8 encoding. 
    # If it's not valid, we assume it's latin1 (Windows default)
    options[:encoding] ||= 'utf-8'
    begin
      initialize_without_encoding data, options
    rescue => ex
      options[:encoding] = 'ISO-8859-1:utf-8'
      data.rewind if data.respond_to? :rewind
      initialize_without_encoding data, options
    end
  end
  alias_method_chain :initialize, :encoding

  class << self
    def open_with_encoding(*args, &block)
      options = if args.last.is_a? Hash then args.pop else Hash.new end

      # Try to parse the file using utf-8 encoding. 
      # If it's not valid, we assume it's latin1 (Windows default)
      options[:encoding] ||= 'utf-8'
      begin
        open_without_encoding *(args + [options]), &block
      rescue
        options[:encoding] = 'ISO-8859-1:utf-8'
        open_without_encoding *(args + [options]), &block
      end
    end
    alias_method_chain :open, :encoding
  end
end
