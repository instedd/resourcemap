require 'spec_helper'

describe CSDNameMapping, :type => :model do
	it '' do
		forename = Field::TextField.make.csd_forename!
		surname = Field::TextField.make.csd_surname!
		common_name_en = Field::TextField.make.csd_common_name! "en"
		common_name_es = Field::TextField.make.csd_common_name! "es"

		m = CSDNameMapping.new "Name 1", [forename, surname, common_name_en, common_name_es]

		expect(m.forename.id).to eq(forename.id)
		expect(m.surname.id).to eq(surname.id)

		expect(m.common_names.size).to eq(2)
		expect(m.common_names[0].class).to be(CSDCommonNameMapping)
		expect(m.common_names[1].class).to be(CSDCommonNameMapping)

		expect(m.common_names[0].field.id).to eq(common_name_en.id)
		expect(m.common_names[1].field.id).to eq(common_name_es.id)
	end
end