require 'spec_helper'

describe CSDContactMapping, :type => :model do 
	describe 'names' do
		it 'is empty' do
			m = CSDContactMapping.new 'Contact', []
			expect(m.names).to be_empty
		end

		it 'has two names' do
			name1 = Field::TextField.make.csd_name! "Name 1", Field::CSDApiConcern::csd_contact_tag
			name2 = Field::TextField.make.csd_name! "Name 2", Field::CSDApiConcern::csd_contact_tag

			m = CSDContactMapping.new "Contact 1", [name1, name2]

			expect(m.names.size).to eq(2)

			expect(m.names[0].class).to be(CSDNameMapping)
			expect(m.names[1].class).to be(CSDNameMapping)
		end
	end

	describe 'addresses' do
		it 'is empty' do
			m = CSDContactMapping.new 'Contact', []
			expect(m.addresses).to be_empty
		end

		it 'has two addresses' do
			address1 = Field::TextField.make.csd_address! "Address 1", Field::CSDApiConcern::csd_contact_tag
			address2 = Field::TextField.make.csd_address! "Address 2", Field::CSDApiConcern::csd_contact_tag

			m = CSDContactMapping.new("Contact 1", [address1, address2])

			expect(m.addresses.size).to eq(2)

			expect(m.addresses[0].class).to be(CSDAddressMapping)
			expect(m.addresses[1].class).to be(CSDAddressMapping)
		end
	end
end