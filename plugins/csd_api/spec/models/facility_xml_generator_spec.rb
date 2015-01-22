require 'spec_helper'
require 'active_support/builder' unless defined?(Builder)

describe FacilityXmlGenerator, :type => :model do
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

	describe 'entityID generation' do
		it 'should use existing entityID annotated field' do
			entity_id_field = layer.identifier_fields.make.csd_facility_entity_id!
			facility_properties[entity_id_field.code] = "value"

			generator = FacilityXmlGenerator.new collection
			expect(generator.generate_entity_id(facility, facility_properties)).to eq("value")
		end

		it 'should generate entityID from UUID' do
			set_facility_attribute "uuid", "1234-5678-9012-3456"

			generator = FacilityXmlGenerator.new collection
			expect(generator.generate_entity_id(facility, facility_properties)).to eq("1234-5678-9012-3456")
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

			doc = Nokogiri.XML xml.target!
			expect(doc.xpath("//codedType").length).to eq(2)

			fruits_xml = doc.xpath("//codedType[@codingScheme='fruits']")
			expect(fruits_xml.attr('code').value).to eq('B')
			expect(fruits_xml.attr('codingScheme').value).to eq('fruits')
			expect(fruits_xml.text).to eq('Banana')

			supermarkets_xml = doc.xpath("//codedType[@codingScheme='supermarkets']")
			expect(supermarkets_xml.attr('code').value).to eq('J')
			expect(supermarkets_xml.attr('codingScheme').value).to eq('supermarkets')
			expect(supermarkets_xml.text).to eq('Jumbo')
		end
	end

	describe 'Other id generation' do
		it '' do
			entity_id_field = layer.identifier_fields.make.csd_facility_entity_id!
			other_id_field = layer.identifier_fields.make(config: { "context" => "DHIS", "agency" => "MOH" }.with_indifferent_access)

			facility_properties[other_id_field.code] = 'my_moh_dhis_id'

			generator = FacilityXmlGenerator.new collection

			xml.tag!("root") do
				generator.generate_other_ids xml, facility_properties
			end

			doc = Nokogiri.XML xml.target!

			expect(doc.xpath("//otherID").length).to eq(1)

			other_id = doc.xpath("//otherID[1]")
			expect(other_id.attr('code').value).to eq('my_moh_dhis_id')
			expect(other_id.attr('assigningAuthorityName').value).to eq('MOH')
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

			doc = Nokogiri.XML xml.target!

			expect(doc.xpath("//contact").length).to eq(2)

			expect(doc.xpath("//contact[1]/person/name/commonName[@language='en']").text).to eq("Anderson, Andrew")
			expect(doc.xpath("//contact[1]/person/name/forename").text).to eq("Andrew")
			expect(doc.xpath("//contact[1]/person/name/surname").text).to eq("Anderson")

			expect(doc.xpath("//contact[1]/person/address/addressLine[@component='streetAddress']").text).to eq("2222 19th Ave SW")
			expect(doc.xpath("//contact[1]/person/address/addressLine[@component='city']").text).to eq("Santa Fe")
			expect(doc.xpath("//contact[1]/person/address/addressLine[@component='stateProvince']").text).to eq("NM")
			expect(doc.xpath("//contact[1]/person/address/addressLine[@component='country']").text).to eq("USA")
			expect(doc.xpath("//contact[1]/person/address/addressLine[@component='postalCode']").text).to eq("87124")


			expect(doc.xpath("//contact[2]/person/name/commonName[@language='en']").text).to eq("Juarez, Julio")
			expect(doc.xpath("//contact[2]/person/name/forename").text).to eq("Julio")
			expect(doc.xpath("//contact[2]/person/name/surname").text).to eq("Juarez")

			expect(doc.xpath("//contact[2]/person/address/addressLine[@component='streetAddress']").text).to eq("2222 19th Ave SW")
			expect(doc.xpath("//contact[2]/person/address/addressLine[@component='city']").text).to eq("Santa Fe")
			expect(doc.xpath("//contact[2]/person/address/addressLine[@component='stateProvince']").text).to eq("NM")
			expect(doc.xpath("//contact[2]/person/address/addressLine[@component='country']").text).to eq("USA")
			expect(doc.xpath("//contact[2]/person/address/addressLine[@component='postalCode']").text).to eq("87124")
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

			doc = Nokogiri.XML xml.target!

			expect(doc.xpath("//language").size).to eq(2)

			language1_xml = doc.xpath("//language[1]")
			expect(language1_xml.attr('code').value).to eq('en')
			expect(language1_xml.attr('codingSchema').value).to eq('BCP 47')
			expect(language1_xml.text).to eq('English')

			language2_xml = doc.xpath("//language[2]")
			expect(language2_xml.attr('code').value).to eq('es')
			expect(language2_xml.attr('codingSchema').value).to eq('BCP 47')
			expect(language2_xml.text).to eq('Spanish')
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

			doc = Nokogiri.XML xml.target!

			expect(doc.xpath("//organizations").size).to eq(1)
			expect(doc.xpath("//organizations/organization").size).to eq(1)

			expect(doc.xpath("//organizations/organization[1]").attr('oid').value).to eq("an_oid")

			expect(doc.xpath("//organizations/organization[1]/service[1]").attr('oid').value).to eq("service1 oid")
			expect(doc.xpath("//organizations/organization[1]/service[1]/name[1]/commonName").attr('language').value).to eq("en")
			expect(doc.xpath("//organizations/organization[1]/service[1]/name[1]/commonName").text).to eq("Connectathon Radiation Therapy")
			expect(doc.xpath("//organizations/organization[1]/service[1]/language[1]").attr('code').value).to eq("en")
			expect(doc.xpath("//organizations/organization[1]/service[1]/language[1]").attr('codingSchema').value).to eq("BCP 47")
			expect(doc.xpath("//organizations/organization[1]/service[1]/language[1]").text).to eq("English")
			expect(doc.xpath("//organizations/organization[1]/service[1]/operatingHours[1]/openFlag[1]").text).to eq("1")
			expect(doc.xpath("//organizations/organization[1]/service[1]/operatingHours[1]/dayOfTheWeek[1]").text).to eq("1")
			expect(doc.xpath("//organizations/organization[1]/service[1]/operatingHours[1]/beginningHour[1]").text).to eq("09:00:00")
			expect(doc.xpath("//organizations/organization[1]/service[1]/operatingHours[1]/endingHour[1]").text).to eq("12:00:00")
			expect(doc.xpath("//organizations/organization[1]/service[1]/operatingHours[1]/beginEffectiveDate[1]").text).to eq("2013-12-01")

			expect(doc.xpath("//organizations/organization[1]/service[1]/operatingHours[2]/openFlag[1]").text).to eq("0")

			expect(doc.xpath("//organizations/organization[1]/service[2]").attr('oid').value).to eq("service2 oid")
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

			doc = Nokogiri.XML xml.target!

			expect(doc.xpath("//operatingHours").size).to eq(2)

			expect(doc.xpath("//operatingHours[1]/openFlag[1]").text).to eq("1")
			expect(doc.xpath("//operatingHours[1]/dayOfTheWeek[1]").text).to eq("1")
			expect(doc.xpath("//operatingHours[1]/beginningHour[1]").text).to eq("08:00:00")
			expect(doc.xpath("//operatingHours[1]/endingHour[1]").text).to eq("18:00:00")
			expect(doc.xpath("//operatingHours[1]/beginEffectiveDate[1]").text).to eq("2013-12-01")

			expect(doc.xpath("//operatingHours[2]/openFlag[1]").text).to eq("0")
		end
	end

	# This will have to wait for a refactor :(
	describe "record" do
		it '' do
			generator = FacilityXmlGenerator.new collection

			xml.tag!("root") do
				generator.generate_record(xml, facility)
			end

			doc = Nokogiri.XML xml.target!

			expect(doc.xpath("//record").size).to eq(1)
			expect(doc.xpath("//record[1]").attr('created').value).to eq(facility["_source"]["created_at"].to_s)
			expect(doc.xpath("//record[1]").attr('updated').value).to eq(facility["_source"]["updated_at"].to_s)
			expect(doc.xpath("//record[1]").attr('status').value).to eq("Active")
			expect(doc.xpath("//record[1]").attr('sourceDirectory').value).to eq("http://localhost:3000")
		end
	end
end
