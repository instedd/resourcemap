require 'spec_helper'

describe Collection::CSDApiConcern do 
	#TODO: Ask why I'm having to provide an email. Something I'm not understanding about machinist.
	let(:user) { User.make email: 'csd@apiconcern.com' }
	let(:collection) { user.create_collection(Collection.make)}
	let(:layer) { collection.layers.make user: user}

	describe 'oid_field' do
		it 'is nil if there is no field with the right metadata' do
			collection.csd_oid_field.should be_nil
		end
		
		it 'chooses the right field given proper metadata configs' do
			oid_field = layer.identifier_fields.make(metadata: { "0" => { "key" => "CSDType", "value"=>"oid"} })

			collection.csd_oid_field.es_code.should eq(oid_field.es_code)
		end		
	end
end