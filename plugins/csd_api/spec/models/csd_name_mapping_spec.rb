require 'spec_helper'

describe CSDNameMapping do
	it '' do
		forename = Field::TextField.make.csd_forename!
		surname = Field::TextField.make.csd_surname!
		common_name_en = Field::TextField.make.csd_common_name! "en"
		common_name_es = Field::TextField.make.csd_common_name! "es"

		m = CSDNameMapping.new "Name 1", [forename, surname, common_name_en, common_name_es]

		m.forename.id.should eq(forename.id)
		m.surname.id.should eq(surname.id)

		m.common_names.should have(2).items
		m.common_names[0].class.should be(CSDCommonNameMapping)
		m.common_names[1].class.should be(CSDCommonNameMapping)

		m.common_names[0].field.id.should eq(common_name_en.id)
		m.common_names[1].field.id.should eq(common_name_es.id)
	end
end