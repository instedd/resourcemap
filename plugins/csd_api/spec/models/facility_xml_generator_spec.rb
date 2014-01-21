require 'spec_helper'

describe FacilityXmlGenerator do
	#TODO: Ask why I'm having to provide an email. Something I'm not understanding about machinist.
	let(:user) { User.make email: 'csd@apiconcern.com' }
	let(:collection) { user.create_collection(Collection.make)}
	let(:layer) { collection.layers.make user: user}
	
	describe 'OID generation' do
		it 'should use existing OID annotated field' do
			# Bad Smell: we need to know how metadata is represented internally to test this.
			# Should be:
			#
			# oid_field = IdentifierField.new
			# oid_field.metadata.put "CSDType", "oid"
			#
			# layer.identifier_fields.add identifier_field
			oid_field = layer.identifier_fields.make( metadata: { "0" => { "key" => "CSDType", "value" => "oid" } })

			# Bad Smell: we need to know how facilities are returned by an ES search to test this
			# Maybe we should have a Facility::CsdApiConcern which knows how to render a CSD XML given a facility
			# or a class that takes an ES facilities result set and efficiently renders a CSD XML.
			facility = { "_source" => 
										{ 
											"properties" => { oid_field.code => "oid_value" } 
										} 
									}

			g = FacilityXmlGenerator.new collection
			
			g.generate_oid(facility, facility["_source"]["properties"]).should eq('oid_value')
		end

		it 'should generate OID from UUID' do
			facility = { "_source" => 
									{ 
										"uuid" => "1234-5678-9012-3456"
									}
								}

			g = FacilityXmlGenerator.new collection

			g.generate_oid(facility, facility["_source"]["properties"]).should eq(g.to_oid("1234-5678-9012-3456"))
		end
	end
end