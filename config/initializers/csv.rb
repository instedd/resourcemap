require 'csv'

# Patch CSV class to always use 'windows-1251:utf-8' encoding.
class CSV
  def initialize_with_encoding(data, options = {})
    options[:encoding] ||= 'windows-1251:utf-8'
    initialize_without_encoding data, options
  end
  alias_method_chain :initialize, :encoding

  class << self
    def open_with_encoding(*args, &block)
      options = if args.last.is_a? Hash then args.pop else Hash.new end
      options[:encoding] ||= 'windows-1251:utf-8'

      open_without_encoding *(args + [options]), &block
    end
    alias_method_chain :open, :encoding
  end
end
