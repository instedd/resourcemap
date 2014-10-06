require 'spec_helper'

describe CSDServiceMapping, :type => :model do
	it 'names' do
		name1 = Field::TextField.make.csd_name!("name1", Field::CSDApiConcern::csd_service_tag)
		name2 = Field::TextField.make.csd_name!("name2", Field::CSDApiConcern::csd_service_tag)

		m = CSDServiceMapping.new "Service", [name1, name2]

		expect(m.names.size).to eq(2)
		expect(m.names[0].class).to be(CSDNameMapping)
		expect(m.names[1].class).to be(CSDNameMapping)
	end

	it 'languages' do
		language1 = Field::TextField.make.csd_language!("lang1", Field::CSDApiConcern::csd_service_tag)
		language2 = Field::TextField.make.csd_language!("lang2", Field::CSDApiConcern::csd_service_tag)

		m = CSDServiceMapping.new "Service", [language1, language2]

		expect(m.languages.size).to eq(2)
		expect(m.languages[0].class).to be(CSDLanguageMapping)
		expect(m.languages[1].class).to be(CSDLanguageMapping)
	end
end