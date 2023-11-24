# if Rails.env == 'development' || Rails.env == 'test'
#   def $stdout.puts_with_color(*args)
#     print "\033[1;32m"
#     puts_without_color *args
#     print "\033[0m"
#   end
#
#   klass = class << $stdout; self; end
#   klass.alias_method_chain :puts, :color
#
#   # :nodoc:
#   module Kernel
#     def p_with_color(*args)
#       print "\033[1;32m"
#       p_without_color *args
#       print "\033[0m"
#     end
#
#     alias_method :p_without_color, :p
#     alias_method :p, :p_with_color
#   end
# end
