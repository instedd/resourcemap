require 'spec_helper'

describe CSDCommonNameMapping do
	it '' do
		common_name_en = Field::TextField.make.csd_common_name! "en"
		
		m = CSDCommonNameMapping.new common_name_en

		m.field.id.should eq(common_name_en.id)
		m.language.should eq("en")
	end
end