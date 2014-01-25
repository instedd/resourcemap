require 'spec_helper'

module CSDFieldSpecHelper
	def dict_to_metadata(dict)
		metadata = {}

		dict.each_with_index { |(key, value), i|
			metadata["#{i}"] = { "key" => key, "value" => value }
		}

		metadata
	end

	Field.kinds.each do |kind|
		class_eval %Q{
			def #{kind}_with_metadata(dict)
				metadata = dict_to_metadata(dict)

				f = Field::#{kind.camelize}Field.make metadata: metadata

				yield f if block_given?

				f
			end
		}
	end
end