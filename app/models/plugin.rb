class Plugin
	include Singleton

	attr_accessor :routes_block

	class << self
		def inherited(plugin)
			super
			all << plugin.instance
		end

		def all
			@plugins ||= []
		end

		def routes &block
			instance.routes_block = block
		end

		def method_missing name, *args
			instance.hooks[name] << args.first
		end
	end

	def name
		self.class.parent_name.underscore
	end

	def hooks
		@hooks ||= Hash.new { |h, k| h[k] = [] }
	end
end