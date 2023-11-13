# if Rails.env == "development"
#   require "ruby-prof"
#
#   class Profiler
#     def self.profile(output_filename = "profile", &block)
#       block_result = nil
#
#       results = RubyProf.profile { block_result = block.call }
#
#       FileUtils.mkdir_p "#{Rails.root}/tmp/performance"
#
#       File.open "#{Rails.root}/tmp/performance/#{output_filename}-graph.html", 'w' do |file|
#         RubyProf::GraphHtmlPrinter.new(results).print(file)
#       end
#
#       File.open "#{Rails.root}/tmp/performance/#{output_filename}-flat.txt", 'w' do |file|
#         RubyProf::FlatPrinterWithLineNumbers.new(results).print(file)
#       end
#
#       File.open "#{Rails.root}/tmp/performance/#{output_filename}-stack.html", 'w' do |file|
#         RubyProf::CallStackPrinter.new(results).print(file)
#       end
#
#       block_result
#     end
#   end
# end
