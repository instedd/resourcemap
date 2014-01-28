require 'spec_helper'
require 'active_support/builder' unless defined?(Builder)

describe FacilityXmlGenerator do
	let(:collection) { Collection.make}
	let(:layer) { collection.layers.make }

	# Bad Smell: we need to know how facilities are returned by an ES search to test this.
	let(:facility) {{ "_source" => { "properties" => {}, "created_at" => DateTime.now, "updated_at" => DateTime.now }}}

	let(:xml) { Builder::XmlMarkup.new(:encoding => 'utf-8', :escape => false) }

	let(:language_config) {{
				options: [
					{id: 1, code: "en", label: "English"}, 
					{id: 2, code: "es", label: "Spanish"},
					{id: 3, code: "fr", label: "French"}
				]	 
			}.with_indifferent_access}

	def set_facility_attribute(key, value)
		facility["_source"][key] = value
	end

	def facility_properties
		facility["_source"]["properties"]
	end

	describe 'OID generation' do
		it 'should use existing OID annotated field' do
			oid_field = layer.identifier_fields.make.csd_facility_oid!
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
			oid_field = layer.identifier_fields.make.csd_facility_oid!
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
				common_name: layer.text_fields.make.csd_contact("Contact 1").csd_name("Name 1", Field::CSDApiConcern::csd_contact_tag).csd_common_name!("en"),
				forename: layer.text_fields.make.csd_contact("Contact 1").csd_name("Name 1", Field::CSDApiConcern::csd_contact_tag).csd_forename!,
				surname: layer.text_fields.make.csd_contact("Contact 1").csd_name("Name 1", Field::CSDApiConcern::csd_contact_tag).csd_surname!,
				street_address: layer.text_fields.make.csd_contact("Contact 1").csd_address("Address 1", Field::CSDApiConcern::csd_contact_tag).csd_address_line!("streetAddress"),
				city: layer.text_fields.make.csd_contact("Contact 1").csd_address("Address 1", Field::CSDApiConcern::csd_contact_tag).csd_address_line!("city"),
				state_province: layer.text_fields.make.csd_contact("Contact 1").csd_address("Address 1", Field::CSDApiConcern::csd_contact_tag).csd_address_line!("stateProvince"),
				country: layer.text_fields.make.csd_contact("Contact 1").csd_address("Address 1", Field::CSDApiConcern::csd_contact_tag).csd_address_line!("country"),
				postal_code: layer.text_fields.make.csd_contact("Contact 1").csd_address("Address 1", Field::CSDApiConcern::csd_contact_tag).csd_address_line!("postalCode")
			}

			julio = {
				common_name: layer.text_fields.make.csd_contact("Contact 2").csd_name("Name 1", Field::CSDApiConcern::csd_contact_tag).csd_common_name!("en"),
				forename: layer.text_fields.make.csd_contact("Contact 2").csd_name("Name 1", Field::CSDApiConcern::csd_contact_tag).csd_forename!,
				surname: layer.text_fields.make.csd_contact("Contact 2").csd_name("Name 1", Field::CSDApiConcern::csd_contact_tag).csd_surname!,
				street_address: layer.text_fields.make.csd_contact("Contact 2").csd_address("Address 1", Field::CSDApiConcern::csd_contact_tag).csd_address_line!("streetAddress"),
				city: layer.text_fields.make.csd_contact("Contact 2").csd_address("Address 1", Field::CSDApiConcern::csd_contact_tag).csd_address_line!("city"),
				state_province: layer.text_fields.make.csd_contact("Contact 2").csd_address("Address 1", Field::CSDApiConcern::csd_contact_tag).csd_address_line!("stateProvince"),
				country: layer.text_fields.make.csd_contact("Contact 2").csd_address("Address 1", Field::CSDApiConcern::csd_contact_tag).csd_address_line!("country"),
				postal_code: layer.text_fields.make.csd_contact("Contact 2").csd_address("Address 1", Field::CSDApiConcern::csd_contact_tag).csd_address_line!("postalCode")
			}

			facility_properties[andrew[:common_name].code] = "Anderson, Andrew"
			facility_properties[andrew[:forename].code] = "Andrew"
			facility_properties[andrew[:surname].code] = "Anderson"
			facility_properties[andrew[:street_address].code] = "2222 19th Ave SW"
			facility_properties[andrew[:city].code] = "Santa Fe"
			facility_properties[andrew[:state_province].code] = "NM"
			facility_properties[andrew[:country].code] = "USA"
			facility_properties[andrew[:postal_code].code] = "87124"

			facility_properties[julio[:common_name].code] = "Juarez, Julio"
			facility_properties[julio[:forename].code] = "Julio"
			facility_properties[julio[:surname].code] = "Juarez"
			facility_properties[julio[:street_address].code] = "2222 19th Ave SW"
			facility_properties[julio[:city].code] = "Santa Fe"
			facility_properties[julio[:state_province].code] = "NM"
			facility_properties[julio[:country].code] = "USA"
			facility_properties[julio[:postal_code].code] = "87124"

			generator = FacilityXmlGenerator.new collection

			xml.tag!("root") do
				generator.generate_contacts xml, facility_properties
			end

			doc = Nokogiri.XML xml

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

	describe 'language generation' do
		it '' do
			language1 = layer.select_one_fields.make(config: language_config).csd_language!("BCP 47", Field::CSDApiConcern::csd_facility_tag)
			language2 = layer.select_one_fields.make(config: language_config).csd_language!("BCP 47", Field::CSDApiConcern::csd_facility_tag)

			facility_properties[language1.code] = "en"
			facility_properties[language2.code] = "es"

			generator = FacilityXmlGenerator.new collection

			xml.tag!("root") do
				generator.generate_languages xml, facility_properties
			end

			doc = Nokogiri.XML xml

			doc.xpath("//language").should have(2).items
			
			language1_xml = doc.xpath("//language[1]")
			language1_xml.attr('code').value.should eq('en')
			language1_xml.attr('codingSchema').value.should eq('BCP 47')
			language1_xml.text.should eq('English')

			language2_xml = doc.xpath("//language[2]")
			language2_xml.attr('code').value.should eq('es')
			language2_xml.attr('codingSchema').value.should eq('BCP 47')
			language2_xml.text.should eq('Spanish')
		end
	end

	describe 'organizations' do
		it '' do
			organization = {
				oid: layer.text_fields.make
					.csd_organization("Organization 1")
					.csd_oid!(Field::CSDApiConcern.csd_organization_tag),
				service1: { 
					oid: layer.text_fields.make
						.csd_organization("Organization 1")
						.csd_service("Service 1")
						.csd_oid!(Field::CSDApiConcern.csd_service_tag),
					name: layer.text_fields.make
						.csd_organization("Organization 1")
						.csd_service("Service 1")
						.csd_name("Name 1", Field::CSDApiConcern::csd_service_tag)
						.csd_common_name!("en"),
					language: layer.select_one_fields.make(config: language_config)
						.csd_organization("Organization 1")
						.csd_service("Service 1")
						.csd_language!("BCP 47", Field::CSDApiConcern::csd_service_tag),
					operating_hours: {
						oh1: {
							open_flag: layer.yes_no_fields.make
								.csd_organization("Organization 1")
								.csd_service("Service 1")
								.csd_operating_hours("OH1", Field::CSDApiConcern::csd_service_tag)
								.csd_open_flag!,
							day_of_the_week: layer.numeric_fields.make
								.csd_organization("Organization 1")
								.csd_service("Service 1")
								.csd_operating_hours("OH1", Field::CSDApiConcern::csd_service_tag)
								.csd_day_of_the_week!,
							beginning_hour: layer.text_fields.make
								.csd_organization("Organization 1")
								.csd_service("Service 1")
								.csd_operating_hours("OH1", Field::CSDApiConcern::csd_service_tag)
								.csd_beginning_hour!,
							ending_hour: layer.text_fields.make
								.csd_organization("Organization 1")
								.csd_service("Service 1")
								.csd_operating_hours("OH1", Field::CSDApiConcern::csd_service_tag)
								.csd_ending_hour!,
							begin_effective_date: layer.text_fields.make
								.csd_organization("Organization 1")
								.csd_service("Service 1")
								.csd_operating_hours("OH1", Field::CSDApiConcern::csd_service_tag)
								.csd_begin_effective_date!
						},
						oh2: {
							open_flag: layer.yes_no_fields.make
								.csd_organization("Organization 1")
								.csd_service("Service 1")
								.csd_operating_hours("OH2", Field::CSDApiConcern::csd_service_tag)
								.csd_open_flag!
						}
					}
				},
				service2: {
					oid: layer.text_fields.make
						.csd_organization("Organization 1")
						.csd_service("Service 2")
						.csd_oid!(Field::CSDApiConcern.csd_service_tag)
				}				
			}

			facility_properties[organization[:oid].code] = "an_oid"

			facility_properties[organization[:service1][:oid].code] = "service1 oid"
			facility_properties[organization[:service1][:name].code] = "Connectathon Radiation Therapy"
			facility_properties[organization[:service1][:language].code] = "en"
			facility_properties[organization[:service1][:operating_hours][:oh1][:open_flag].code] = true
			facility_properties[organization[:service1][:operating_hours][:oh1][:day_of_the_week].code] = 1
			facility_properties[organization[:service1][:operating_hours][:oh1][:beginning_hour].code] = "09:00:00"
			facility_properties[organization[:service1][:operating_hours][:oh1][:ending_hour].code] = "12:00:00"
			facility_properties[organization[:service1][:operating_hours][:oh1][:begin_effective_date].code] = "2013-12-01"

			facility_properties[organization[:service1][:operating_hours][:oh2][:open_flag].code] = false

			facility_properties[organization[:service2][:oid].code] = "service2 oid"

			generator = FacilityXmlGenerator.new collection

			xml.tag!("root") do
				generator.generate_organizations xml, facility_properties
			end

			doc = Nokogiri.XML xml

			doc.xpath("//organizations").should have(1).items
			doc.xpath("//organizations/organization").should have(1).item

			doc.xpath("//organizations/organization[1]").attr('oid').value.should eq("an_oid")

			doc.xpath("//organizations/organization[1]/service[1]").attr('oid').value.should eq("service1 oid")
			doc.xpath("//organizations/organization[1]/service[1]/name[1]/commonName").attr('language').value.should eq("en")
			doc.xpath("//organizations/organization[1]/service[1]/name[1]/commonName").text.should eq("Connectathon Radiation Therapy")
			doc.xpath("//organizations/organization[1]/service[1]/language[1]").attr('code').value.should eq("en")
			doc.xpath("//organizations/organization[1]/service[1]/language[1]").attr('codingSchema').value.should eq("BCP 47")
			doc.xpath("//organizations/organization[1]/service[1]/language[1]").text.should eq("English")
			doc.xpath("//organizations/organization[1]/service[1]/operatingHours[1]/openFlag[1]").text.should eq("1")
			doc.xpath("//organizations/organization[1]/service[1]/operatingHours[1]/dayOfTheWeek[1]").text.should eq("1")
			doc.xpath("//organizations/organization[1]/service[1]/operatingHours[1]/beginningHour[1]").text.should eq("09:00:00")
			doc.xpath("//organizations/organization[1]/service[1]/operatingHours[1]/endingHour[1]").text.should eq("12:00:00")
			doc.xpath("//organizations/organization[1]/service[1]/operatingHours[1]/beginEffectiveDate[1]").text.should eq("2013-12-01")

			doc.xpath("//organizations/organization[1]/service[1]/operatingHours[2]/openFlag[1]").text.should eq("0")

			doc.xpath("//organizations/organization[1]/service[2]").attr('oid').value.should eq("service2 oid")
		end
	end

	describe 'facility operating hours' do
		it '' do
			facility_oh1 = {
				open_flag: layer.yes_no_fields.make
					.csd_operating_hours("OH1", Field::CSDApiConcern::csd_facility_tag)
					.csd_open_flag!,
				day_of_the_week: layer.numeric_fields.make
					.csd_operating_hours("OH1", Field::CSDApiConcern::csd_facility_tag)
					.csd_day_of_the_week!,
				beginning_hour: layer.text_fields.make
					.csd_operating_hours("OH1", Field::CSDApiConcern::csd_facility_tag)
					.csd_beginning_hour!,
				ending_hour: layer.text_fields.make
					.csd_operating_hours("OH1", Field::CSDApiConcern::csd_facility_tag)
					.csd_ending_hour!,
				begin_effective_date: layer.text_fields.make
					.csd_operating_hours("OH1", Field::CSDApiConcern::csd_facility_tag)
					.csd_begin_effective_date!
			}

			facility_oh2 = {
				open_flag: layer.yes_no_fields.make
					.csd_operating_hours("OH2", Field::CSDApiConcern::csd_facility_tag)
					.csd_open_flag!
			}
			
			facility_properties[facility_oh1[:open_flag].code] = true
			facility_properties[facility_oh1[:day_of_the_week].code] = 1
			facility_properties[facility_oh1[:beginning_hour].code] = "08:00:00"
			facility_properties[facility_oh1[:ending_hour].code] = "18:00:00"
			facility_properties[facility_oh1[:begin_effective_date].code] = "2013-12-01"

			facility_properties[facility_oh2[:open_flag].code] = false

			generator = FacilityXmlGenerator.new collection

			xml.tag!("root") do
				generator.generate_operating_hours xml, facility_properties, collection.csd_operating_hours
			end

			doc = Nokogiri.XML xml

			doc.xpath("//operatingHours").should have(2).items

			doc.xpath("//operatingHours[1]/openFlag[1]").text.should eq("1")
			doc.xpath("//operatingHours[1]/dayOfTheWeek[1]").text.should eq("1")
			doc.xpath("//operatingHours[1]/beginningHour[1]").text.should eq("08:00:00")
			doc.xpath("//operatingHours[1]/endingHour[1]").text.should eq("18:00:00")
			doc.xpath("//operatingHours[1]/beginEffectiveDate[1]").text.should eq("2013-12-01")

			doc.xpath("//operatingHours[2]/openFlag[1]").text.should eq("0")
		end
	end

	# This will have to wait for a refactor :(
	describe "record" do
		it '' do
			generator = FacilityXmlGenerator.new collection

			xml.tag!("root") do
				generator.generate_record(xml, facility)
			end

			doc = Nokogiri.XML xml

			doc.xpath("//record").should have(1).item
			doc.xpath("//record[1]").attr('created').value.should eq(facility["_source"]["created_at"].to_s)
			doc.xpath("//record[1]").attr('updated').value.should eq(facility["_source"]["updated_at"].to_s)
			doc.xpath("//record[1]").attr('status').value.should eq("Active")
			doc.xpath("//record[1]").attr('sourceDirectory').value.should eq("http://localhost:3000")
		end
	end
end