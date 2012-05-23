require 'csv'

class ResilientCSV < CSV
  def self.foreach(path, options = {}, &block)
    super
  rescue ArgumentError
    super path, options.merge(encoding: 'windows-1251:utf-8'), &block
  end

  def self.read(path, options = {})
    super
  rescue ArgumentError
    super path, options.merge(encoding: 'windows-1251:utf-8')
  end
end
