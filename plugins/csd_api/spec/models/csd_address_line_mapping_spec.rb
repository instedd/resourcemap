require 'spec_helper'

describe CSDAddressLineMapping, :type => :model do
	it 'component' do
		f = Field::TextField.make.csd_address_line!("oneComponent")
		m = CSDAddressLineMapping.new f
		expect(m.component).to eq("oneComponent")
	end
end