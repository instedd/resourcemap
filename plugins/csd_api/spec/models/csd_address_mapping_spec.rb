require 'spec_helper'

describe CSDAddressMapping, :type => :model do 
	describe 'address_lines' do
		it 'is empty' do
			m = CSDAddressMapping.new 'An address', []
			expect(m.address_lines).to be_empty
		end

		it 'has two address lines' do
			address_line1 = Field::TextField.make.csd_address_line!("Component1")
			address_line2 = Field::TextField.make.csd_address_line!("Component2")

			m = CSDAddressMapping.new 'An address', [address_line1, address_line2]
			expect(m.address_lines.size).to eq(2)

			expect(m.address_lines[0].class).to be(CSDAddressLineMapping)
			expect(m.address_lines[1].class).to be(CSDAddressLineMapping)
		end
	end
end