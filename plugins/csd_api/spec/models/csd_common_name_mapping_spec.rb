require 'spec_helper'

describe CSDCommonNameMapping, :type => :model do
	it '' do
		common_name_en = Field::TextField.make.csd_common_name! "en"
		
		m = CSDCommonNameMapping.new common_name_en

		expect(m.field.id).to eq(common_name_en.id)
		expect(m.language).to eq("en")
	end
end