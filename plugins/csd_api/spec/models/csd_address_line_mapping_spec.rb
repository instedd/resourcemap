require 'spec_helper'

describe CSDAddressLineMapping do
	it 'component' do
		f = Field::TextField.make.csd_address_line!("oneComponent")
		m = CSDAddressLineMapping.new f
		m.component.should eq("oneComponent")
	end
end