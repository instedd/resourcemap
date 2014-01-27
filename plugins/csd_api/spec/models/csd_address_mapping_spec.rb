require 'spec_helper'

describe CSDAddressMapping do 
	describe 'address_lines' do
		it 'is empty' do
			m = CSDAddressMapping.new 'An address', []
			m.address_lines.should be_empty
		end

		it 'has two address lines' do
			#Bad smell, we shouldn't have to define the contact, so that we can reuse addresses 
			#below different kinds of elements
			address_line1 = Field::TextField.make.csd_address_line!("Contact 1", "Address 1", "Component1")
			address_line2 = Field::TextField.make.csd_address_line!("Contact 1", "Address 1", "Component2")

			m = CSDAddressMapping.new 'An address', [address_line1, address_line2]
			m.address_lines.should have(2).items

			m.address_lines[0].class.should be(CSDAddressLineMapping)
			m.address_lines[1].class.should be(CSDAddressLineMapping)
		end
	end
end