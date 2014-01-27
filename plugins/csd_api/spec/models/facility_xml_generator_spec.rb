require 'spec_helper'
require 'active_support/builder' unless defined?(Builder)

describe FacilityXmlGenerator do
	let(:collection) { Collection.make}
	let(:layer) { collection.layers.make }

	# Bad Smell: we need to know how facilities are returned by an ES search to test this.
	let(:facility) {{ "_source" => { "properties" => {} }}}

	let(:xml) { Builder::XmlMarkup.new(:encoding => 'utf-8', :escape => false) }

	def set_facility_attribute(key, value)
		facility["_source"][key] = value
	end

	def facility_properties
		facility["_source"]["properties"]
	end

	describe 'OID generation' do
		it 'should use existing OID annotated field' do
			oid_field = layer.identifier_fields.make.csd_oid!
			facility_properties[oid_field.code] = "oid_value"
			
			generator = FacilityXmlGenerator.new collection
			generator.generate_oid(facility, facility_properties).should eq("oid_value")
		end

		it 'should generate OID from UUID' do
			set_facility_attribute "uuid", "1234-5678-9012-3456"

			generator = FacilityXmlGenerator.new collection
			generator.generate_oid(facility, facility_properties).should eq(generator.to_oid("1234-5678-9012-3456"))
		end
	end

	describe 'Coded Types generation' do
		let(:coded_fruits) {
			coded_fruits = layer.select_one_fields.make(
				config: {
					options: [
						{id: 1, code: "A", label: "Apple"}, 
						{id: 2, code: "B", label: "Banana"},
						{id: 3, code: "P", label: "Peach"}
					]	 
				}.with_indifferent_access
			).csd_coded_type!("fruits")
		}

		let(:coded_supermarkets) {
			coded_supermarkets = layer.select_one_fields.make(
				config: {
					options: [
						{id: 1, code: "C", label: "Carrefour"}, 
						{id: 2, code: "J", label: "Jumbo"}
					] 
				}.with_indifferent_access
			).csd_coded_type!("supermarkets")
		}

		it '' do
			facility_properties[coded_fruits.code] = 'B'
			facility_properties[coded_supermarkets.code] = 'J'			

			generator = FacilityXmlGenerator.new collection

			xml.tag!("root") do
				generator.generate_coded_types xml, facility_properties
			end

			doc = Nokogiri.XML xml

			doc.xpath("//codedType").length.should eq(2)
			
			fruits_xml = doc.xpath("//codedType[@codingSchema='fruits']")
			fruits_xml.attr('code').value.should eq('B')
			fruits_xml.attr('codingSchema').value.should eq('fruits')
			fruits_xml.text.should eq('Banana')

			supermarkets_xml = doc.xpath("//codedType[@codingSchema='supermarkets']")
			supermarkets_xml.attr('code').value.should eq('J')
			supermarkets_xml.attr('codingSchema').value.should eq('supermarkets')
			supermarkets_xml.text.should eq('Jumbo')
		end
	end

	describe 'Other id generation' do
		it '' do
			oid_field = layer.identifier_fields.make.csd_oid!
			other_id_field = layer.identifier_fields.make(config: { "context" => "DHIS", "agency" => "MOH" }.with_indifferent_access)

			facility_properties[other_id_field.code] = 'my_moh_dhis_id'

			generator = FacilityXmlGenerator.new collection

			xml.tag!("root") do
				generator.generate_other_ids xml, facility_properties
			end

			doc = Nokogiri.XML xml

			doc.xpath("//otherID").length.should eq(1)

			other_id = doc.xpath("//otherID[1]")
			other_id.attr('code').value.should eq('my_moh_dhis_id')
			other_id.attr('assigningAuthorityName').value.should eq('MOH')
		end
	end

	describe 'Contact generation' do
		it '' do
			andrew = {
				common_name: layer.text_fields.make.csd_contact_common_name!("Contact 1", "Name 1", "en"),
				forename: layer.text_fields.make.csd_forename!("Contact 1", "Name 1"),
				surname: layer.text_fields.make.csd_surname!("Contact 1", "Name 1")
			}

			julio = {
				common_name: layer.text_fields.make.csd_contact_common_name!("Contact 2", "Name 1", "en"),
				forename: layer.text_fields.make.csd_forename!("Contact 2", "Name 1"),
				surname: layer.text_fields.make.csd_surname!("Contact 2", "Name 1")
			}

			facility_properties[andrew[:common_name].code] = "Anderson, Andrew"
			facility_properties[andrew[:forename].code] = "Andrew"
			facility_properties[andrew[:surname].code] = "Anderson"

			facility_properties[julio[:common_name].code] = "Juarez, Julio"
			facility_properties[julio[:forename].code] = "Julio"
			facility_properties[julio[:surname].code] = "Juarez"

			generator = FacilityXmlGenerator.new collection

			xml.tag!("root") do
				generator.generate_contacts xml, facility_properties
			end

			doc = Nokogiri.XML xml

			binding.pry

			doc.xpath("//contact").length.should eq(2)

			doc.xpath("//contact[1]/person/name/commonName[@language='en']").text.should eq("Anderson, Andrew")
			doc.xpath("//contact[1]/person/name/forename").text.should eq("Andrew")
			doc.xpath("//contact[1]/person/name/surname").text.should eq("Anderson")

			doc.xpath("//contact[1]/person/address/addressLine[@component='streetAddress']").text.should eq("2222 19th Ave SW")
			doc.xpath("//contact[1]/person/address/addressLine[@component='city']").text.should eq("Santa Fe")
			doc.xpath("//contact[1]/person/address/addressLine[@component='stateProvince']").text.should eq("NM")
			doc.xpath("//contact[1]/person/address/addressLine[@component='country']").text.should eq("USA")
			doc.xpath("//contact[1]/person/address/addressLine[@component='postalCode']").text.should eq("87124")

			
			doc.xpath("//contact[2]/person/name/commonName[@language='en']").text.should eq("Juarez, Julio")
			doc.xpath("//contact[2]/person/name/forename").text.should eq("Julio")
			doc.xpath("//contact[2]/person/name/surname").text.should eq("Juarez")

			doc.xpath("//contact[2]/person/address/addressLine[@component='streetAddress']").text.should eq("2222 19th Ave SW")
			doc.xpath("//contact[2]/person/address/addressLine[@component='city']").text.should eq("Santa Fe")
			doc.xpath("//contact[2]/person/address/addressLine[@component='stateProvince']").text.should eq("NM")
			doc.xpath("//contact[2]/person/address/addressLine[@component='country']").text.should eq("USA")
			doc.xpath("//contact[2]/person/address/addressLine[@component='postalCode']").text.should eq("87124")
		end
	end
end