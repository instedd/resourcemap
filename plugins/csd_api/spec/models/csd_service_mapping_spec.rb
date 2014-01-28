require 'spec_helper'

describe CSDServiceMapping do
	it 'names' do
		name1 = Field::TextField.make.csd_name!("name1", Field::CSDApiConcern::csd_service_tag)
		name2 = Field::TextField.make.csd_name!("name2", Field::CSDApiConcern::csd_service_tag)

		m = CSDServiceMapping.new "Service", [name1, name2]

		m.names.should have(2).items
		m.names[0].class.should be(CSDNameMapping)
		m.names[1].class.should be(CSDNameMapping)
	end

	it 'languages' do
		language1 = Field::TextField.make.csd_language!("lang1", Field::CSDApiConcern::csd_service_tag)
		language2 = Field::TextField.make.csd_language!("lang2", Field::CSDApiConcern::csd_service_tag)

		m = CSDServiceMapping.new "Service", [language1, language2]

		m.languages.should have(2).items
		m.languages[0].class.should be(CSDLanguageMapping)
		m.languages[1].class.should be(CSDLanguageMapping)
	end
end