# encoding: UTF-8
class SampleCollectionGenerator
  def self.fill(collection)
    user = collection.get_user_owner
    layer = collection.layers.create! name: 'Connectathon Fields', ord: 1, user: user
    coded_type_medical_specialty = layer.select_one_fields.create!(ord: 1, name: 'Medical Specialty', code: 'medical_specialty',
      config: {'options' =>[
        {'id' => 1, 'code' => '103-110', 'label' => 'Radiology - Imaging Services'},
        {'id' => 2, 'code' => '103-003', 'label' => 'Dialysis'}]}).csd_coded_type! "1.3.6.1.4.1.21367.100.1"

    entity_id_field = layer.identifier_fields.create!(ord: 2, name: "Entity ID", code: "entity_id", config: {"context"=>"test", "agency"=>"test", "format"=>"Normal"}).csd_facility_entity_id!

    contact_1_common_name_field = layer.text_fields.create!(ord: 3, name: "Common Name Contact 1", code: 'common_name_contact_1')
      .csd_contact("Contact 1").csd_name("Name 1", Field::CSDApiConcern::csd_contact_tag).csd_common_name!("en")
    contact_1_forename_field = layer.text_fields.create!(ord: 4, name: "Forename Contact 1", code: 'forename_contact_1')
      .csd_contact("Contact 1").csd_name("Name 1", Field::CSDApiConcern::csd_contact_tag).csd_forename!
    contact_1_surname_field = layer.text_fields.create!(ord: 5, name: "Surname Contact 1", code: 'surname_contact_1')
      .csd_contact("Contact 1").csd_name("Name 1", Field::CSDApiConcern::csd_contact_tag).csd_surname!
    contact_1_street_address_field = layer.text_fields.create!(ord: 6, name: "StreetAddress Contact 1", code: "street_address_contact_1")
      .csd_contact("Contact 1").csd_address("Address 1", Field::CSDApiConcern::csd_contact_tag).csd_address_line!("streetAddress")
    contact_1_city_field =  layer.text_fields.create!(ord: 7, name: "City Contact 1", code: 'city_contact_1')
      .csd_contact("Contact 1").csd_address("Address 1", Field::CSDApiConcern::csd_contact_tag).csd_address_line!("city")
    contact_1_state_province_field = layer.text_fields.create!(ord: 8, name: "StateProvince Contact 1", code: 'state_province_contact_1')
      .csd_contact("Contact 1").csd_address("Address 1", Field::CSDApiConcern::csd_contact_tag).csd_address_line!("stateProvince")
    contact_1_country_field = layer.text_fields.create!(ord: 9, name: "Country Contact 1", code: 'country_contact_1')
      .csd_contact("Contact 1").csd_address("Address 1", Field::CSDApiConcern::csd_contact_tag).csd_address_line!("country")
    contact_1_postal_code_field = layer.text_fields.create!(ord: 10, name: "PostalCode Contact 1", code: 'postal_code_contact_1')
      .csd_contact("Contact 1").csd_address("Address 1", Field::CSDApiConcern::csd_contact_tag).csd_address_line!("postalCode")


    contact_2_common_name_field = layer.text_fields.create!(ord: 11, name: "Common Name Contact 2", code: 'common_name_contact_2')
      .csd_contact("Contact 2").csd_name("Name 2", Field::CSDApiConcern::csd_contact_tag).csd_common_name!("en")
    contact_2_forename_field = layer.text_fields.create!(ord: 12, name: "Forename Contact 2", code: 'forename_contact_2')
      .csd_contact("Contact 2").csd_name("Name 2", Field::CSDApiConcern::csd_contact_tag).csd_forename!
    contact_2_surname_field = layer.text_fields.create!(ord: 13, name: "Surname Contact 2", code: 'surname_contact_2')
      .csd_contact("Contact 2").csd_name("Name 2", Field::CSDApiConcern::csd_contact_tag).csd_surname!
    contact_2_street_address_field = layer.text_fields.create!(ord: 6, name: "StreetAddress Contact 2", code: "street_address_contact_2")
      .csd_contact("Contact 2").csd_address("Address 2", Field::CSDApiConcern::csd_contact_tag).csd_address_line!("streetAddress")
    contact_2_city_field =  layer.text_fields.create!(ord: 7, name: "City Contact 2", code: 'city_contact_2')
      .csd_contact("Contact 2").csd_address("Address 2", Field::CSDApiConcern::csd_contact_tag).csd_address_line!("city")
    contact_2_state_province_field = layer.text_fields.create!(ord: 8, name: "StateProvince Contact 2", code: 'state_province_contact_2')
      .csd_contact("Contact 2").csd_address("Address 2", Field::CSDApiConcern::csd_contact_tag).csd_address_line!("stateProvince")
    contact_2_country_field = layer.text_fields.create!(ord: 9, name: "Country Contact 2", code: 'country_contact_2')
      .csd_contact("Contact 2").csd_address("Address 2", Field::CSDApiConcern::csd_contact_tag).csd_address_line!("country")
    contact_2_postal_code_field = layer.text_fields.create!(ord: 10, name: "PostalCode Contact 2", code: 'postal_code_contact_2')
      .csd_contact("Contact 2").csd_address("Address 2", Field::CSDApiConcern::csd_contact_tag).csd_address_line!("postalCode")

    language_config = {
      options: [
        {id: 1, code: "en", label: "English"},
        {id: 2, code: "es", label: "Spanish"},
        {id: 3, code: "fr", label: "French"}
      ]
    }.with_indifferent_access

    language_1_field = layer.select_one_fields.create!(ord: 11, name: "Language 1", code: 'language_1', config: language_config)
      .csd_language!("BCP 47", Field::CSDApiConcern::csd_facility_tag)
    language_2_field = layer.select_one_fields.create!(ord: 12, name: "Language 2", code: 'language_2', config: language_config)
      .csd_language!("BCP 47", Field::CSDApiConcern::csd_facility_tag)

    oh_1_open_flag_field = layer.yes_no_fields.create!(ord: 13, name: "Open Flag OH1", code: 'open_flag_oh1')
        .csd_operating_hours("OH1", Field::CSDApiConcern::csd_facility_tag)
        .csd_open_flag!
    oh_1_day_of_the_week_field = layer.numeric_fields.create!(ord: 14, name: "Day of Week OH1", code: 'day_of_week_oh1')
      .csd_operating_hours("OH1", Field::CSDApiConcern::csd_facility_tag)
      .csd_day_of_the_week!
    oh_1_beginning_hour_field = layer.text_fields.create!(ord: 15, name: "Beginning Hour OH1", code: 'beginning_hour_oh1')
      .csd_operating_hours("OH1", Field::CSDApiConcern::csd_facility_tag)
      .csd_beginning_hour!
    oh_1_ending_hour_field = layer.text_fields.create!(ord: 16, name: "Ending Hour OH1", code: 'ending_hour_oh1')
      .csd_operating_hours("OH1", Field::CSDApiConcern::csd_facility_tag)
      .csd_ending_hour!
    oh_1_begin_effective_date_field = layer.text_fields.create!(ord: 17, name: "Begin Effective OH1", code: 'begin_effective_oh1')
      .csd_operating_hours("OH1", Field::CSDApiConcern::csd_facility_tag)
      .csd_begin_effective_date!

    oh_2_open_flag_field = layer.yes_no_fields.create!(ord: 18, name: "Open Flag OH2", code: 'open_flag_oh2')
        .csd_operating_hours("OH2", Field::CSDApiConcern::csd_facility_tag)
        .csd_open_flag!
    oh_2_day_of_the_week_field = layer.numeric_fields.create!(ord: 19, name: "Day of Week OH2", code: 'day_of_week_oh2')
      .csd_operating_hours("OH2", Field::CSDApiConcern::csd_facility_tag)
      .csd_day_of_the_week!
    oh_2_beginning_hour_field = layer.text_fields.create!(ord: 20, name: "Beginning Hour OH2", code: 'beginning_hour_oh2')
      .csd_operating_hours("OH2", Field::CSDApiConcern::csd_facility_tag)
      .csd_beginning_hour!
    oh_2_ending_hour_field = layer.text_fields.create!(ord: 21, name: "Ending Hour OH2", code: 'ending_hour_oh2')
      .csd_operating_hours("OH2", Field::CSDApiConcern::csd_facility_tag)
      .csd_ending_hour!
    oh_2_begin_effective_date_field = layer.text_fields.create!(ord: 22, name: "Begin Effective OH2", code: 'begin_effective_oh2')
      .csd_operating_hours("OH2", Field::CSDApiConcern::csd_facility_tag)
      .csd_begin_effective_date!

    oh_3_open_flag_field = layer.yes_no_fields.create!(ord: 23, name: "Open Flag OH3", code: 'open_flag_oh3')
        .csd_operating_hours("OH3", Field::CSDApiConcern::csd_facility_tag)
        .csd_open_flag!
    oh_3_day_of_the_week_field = layer.numeric_fields.create!(ord: 24, name: "Day of Week OH3", code: 'day_of_week_oh3')
      .csd_operating_hours("OH3", Field::CSDApiConcern::csd_facility_tag)
      .csd_day_of_the_week!
    oh_3_beginning_hour_field = layer.text_fields.create!(ord: 25, name: "Beginning Hour OH3", code: 'beginning_hour_oh3')
      .csd_operating_hours("OH3", Field::CSDApiConcern::csd_facility_tag)
      .csd_beginning_hour!
    oh_3_ending_hour_field = layer.text_fields.create!(ord: 26, name: "Ending Hour OH3", code: 'ending_hour_oh3')
      .csd_operating_hours("OH3", Field::CSDApiConcern::csd_facility_tag)
      .csd_ending_hour!
    oh_3_begin_effective_date_field = layer.text_fields.create!(ord: 27, name: "Begin Effective OH3", code: 'begin_effective_oh3')
      .csd_operating_hours("OH3", Field::CSDApiConcern::csd_facility_tag)
      .csd_begin_effective_date!

    oh_4_open_flag_field = layer.yes_no_fields.create!(ord: 28, name: "Open Flag OH4", code: 'open_flag_oh4')
        .csd_operating_hours("OH4", Field::CSDApiConcern::csd_facility_tag)
        .csd_open_flag!
    oh_4_day_of_the_week_field = layer.numeric_fields.create!(ord: 29, name: "Day of Week OH4", code: 'day_of_week_oh4')
      .csd_operating_hours("OH4", Field::CSDApiConcern::csd_facility_tag)
      .csd_day_of_the_week!
    oh_4_beginning_hour_field = layer.text_fields.create!(ord: 30, name: "Beginning Hour OH4", code: 'beginning_hour_oh4')
      .csd_operating_hours("OH4", Field::CSDApiConcern::csd_facility_tag)
      .csd_beginning_hour!
    oh_4_ending_hour_field = layer.text_fields.create!(ord: 31, name: "Ending Hour OH4", code: 'ending_hour_oh4')
      .csd_operating_hours("OH4", Field::CSDApiConcern::csd_facility_tag)
      .csd_ending_hour!
    oh_4_begin_effective_date_field = layer.text_fields.create!(ord: 32, name: "Begin Effective OH4", code: 'begin_effective_oh4')
      .csd_operating_hours("OH4", Field::CSDApiConcern::csd_facility_tag)
      .csd_begin_effective_date!

    oh_5_open_flag_field = layer.yes_no_fields.create!(ord: 33, name: "Open Flag OH5", code: 'open_flag_oh5')
        .csd_operating_hours("OH5", Field::CSDApiConcern::csd_facility_tag)
        .csd_open_flag!
    oh_5_day_of_the_week_field = layer.numeric_fields.create!(ord: 34, name: "Day of Week OH5", code: 'day_of_week_oh5')
      .csd_operating_hours("OH5", Field::CSDApiConcern::csd_facility_tag)
      .csd_day_of_the_week!
    oh_5_beginning_hour_field = layer.text_fields.create!(ord: 35, name: "Beginning Hour OH5", code: 'beginning_hour_oh5')
      .csd_operating_hours("OH5", Field::CSDApiConcern::csd_facility_tag)
      .csd_beginning_hour!
    oh_5_ending_hour_field = layer.text_fields.create!(ord: 36, name: "Ending Hour OH5", code: 'ending_hour_oh5')
      .csd_operating_hours("OH5", Field::CSDApiConcern::csd_facility_tag)
      .csd_ending_hour!
    oh_5_begin_effective_date_field = layer.text_fields.create!(ord: 37, name: "Begin Effective OH5", code: 'begin_effective_oh5')
      .csd_operating_hours("OH5", Field::CSDApiConcern::csd_facility_tag)
      .csd_begin_effective_date!

    billing_address_street_field = layer.text_fields.create!(ord: 38, name: "Billing Address Street", code: "billing_address_street").csd_facility_address!("Billing").csd_address_code!("streetAddress")
    billing_address_city_field = layer.text_fields.create!(ord: 39, name: "Billing Address City", code: "billing_address_city").csd_facility_address!("Billing").csd_address_code!("city")
    billing_address_state_field = layer.text_fields.create!(ord: 40, name: "Billing Address stateProvince", code: "billing_address_state_province").csd_facility_address!("Billing").csd_address_code!("stateProvince")
    billing_address_country_field = layer.text_fields.create!(ord: 41, name: "Billing Address Country", code: "billing_address_state_country").csd_facility_address!("Billing").csd_address_code!("country")
    billing_address_postal_code_field = layer.text_fields.create!(ord: 42, name: "Billing Address PostalCode", code: "billing_address_state_postal_code").csd_facility_address!("Billing").csd_address_code!("postalCode")

    practice_address_street_field = layer.text_fields.create!(ord: 43, name: "Practice Address Street", code: "practice_address_street").csd_facility_address!("Practice").csd_address_code!("streetAddress")
    practice_address_city_field = layer.text_fields.create!(ord: 44, name: "Practice Address City", code: "practice_address_city").csd_facility_address!("Practice").csd_address_code!("city")
    practice_address_state_field = layer.text_fields.create!(ord: 45, name: "Practice Address stateProvince", code: "practice_address_state_province").csd_facility_address!("Practice").csd_address_code!("stateProvince")
    practice_address_country_field = layer.text_fields.create!(ord: 46, name: "Practice Address Country", code: "practice_address_state_country").csd_facility_address!("Practice").csd_address_code!("country")
    practice_address_postal_code_field = layer.text_fields.create!(ord: 47, name: "Practice Address PostalCode", code: "practice_address_state_postal_code").csd_facility_address!("Practice").csd_address_code!("postalCode")

    organization_1_field = layer.text_fields.create!(ord: 48, name: "Organization 1", code: "org_1")
      .csd_organization("Org1").csd_oid!(Field::CSDApiConcern::csd_organization_tag)

    service_1_field = layer.text_fields.create!(ord: 49, name: "Service 1", code: "service_1")
      .csd_organization("Org1").csd_service!("Service 1").csd_oid!(Field::CSDApiConcern::csd_service_tag)
    service_1_name_field = layer.text_fields.create!(ord: 50, name: "Service 1 Name", code: "service_1_name")
      .csd_organization("Org1").csd_service!("Service 1").csd_name!("name1", Field::CSDApiConcern::csd_service_tag)
    service_1_language_field = layer.select_one_fields.create!(ord: 51, name: "Service 1 Language", code: "service_1_language", config: language_config)
      .csd_organization("Org1").csd_service!("Service 1").csd_language!("BCP 47", Field::CSDApiConcern::csd_service_tag)

    service_2_field = layer.text_fields.create!(ord: 52, name: "Service 2", code: "service_2")
      .csd_organization("Org1").csd_service!("Service 2").csd_oid!(Field::CSDApiConcern::csd_service_tag)
    service_2_name_field = layer.text_fields.create!(ord: 53, name: "Service 2 Name", code: "service_2_name")
      .csd_organization("Org1").csd_service!("Service 2").csd_name!("name1", Field::CSDApiConcern::csd_service_tag)
    service_2_language_field = layer.select_one_fields.create!(ord: 54, name: "Service 2 Language", code: "service_2_language", config: language_config)
      .csd_organization("Org1").csd_service!("Service 2").csd_language!("BCP 47", Field::CSDApiConcern::csd_service_tag)

    service_3_field = layer.text_fields.create!(ord: 55, name: "Service 3", code: "service_3")
      .csd_organization("Org1").csd_service!("Service 3").csd_oid!(Field::CSDApiConcern::csd_service_tag)
    service_3_name_field = layer.text_fields.create!(ord: 56, name: "Service 3 Name", code: "service_3_name")
      .csd_organization("Org1").csd_service!("Service 3").csd_name!("name3", Field::CSDApiConcern::csd_service_tag)
    service_3_language_field = layer.select_one_fields.create!(ord: 57, name: "Service 3 Language", code: "service_3_language", config: language_config)
      .csd_organization("Org1").csd_service!("Service 3").csd_language!("BCP 47", Field::CSDApiConcern::csd_service_tag)

    service_4_field = layer.text_fields.create!(ord: 58, name: "Service 4", code: "service_4")
      .csd_organization("Org1").csd_service!("Service 4").csd_oid!(Field::CSDApiConcern::csd_service_tag)
    service_4_name_field = layer.text_fields.create!(ord: 59, name: "Service 4 Name", code: "service_4_name")
      .csd_organization("Org1").csd_service!("Service 4").csd_name!("name4", Field::CSDApiConcern::csd_service_tag)
    service_4_language_field = layer.select_one_fields.create!(ord: 60, name: "Service 4 Language", code: "service_4_language", config: language_config)
      .csd_organization("Org1").csd_service!("Service 4").csd_language!("BCP 47", Field::CSDApiConcern::csd_service_tag)

    service_1_oh_1_open_flag_field = layer.yes_no_fields.create!(ord: 61, name: "Service 1 Operating Hour 1 Open Flag", code: 'service_1_open_flag_oh1')
        .csd_organization("Org1").csd_service!("Service 1")
        .csd_operating_hours("OH1", Field::CSDApiConcern::csd_service_tag)
        .csd_open_flag!
    service_1_oh_1_day_of_the_week_field = layer.numeric_fields.create!(ord: 62, name: "Service 1 Day of Week OH1", code: 'service_1_day_of_week_oh1')
      .csd_organization("Org1").csd_service!("Service 1")
      .csd_operating_hours("OH1", Field::CSDApiConcern::csd_service_tag).csd_day_of_the_week!
    service_1_oh_1_beginning_hour_field = layer.text_fields.create!(ord: 63, name: "Service 1Beginning Hour OH1", code: 'service_1_beginning_hour_oh1')
      .csd_organization("Org1").csd_service!("Service 1")
      .csd_operating_hours("OH1", Field::CSDApiConcern::csd_service_tag).csd_beginning_hour!
    service_1_oh_1_ending_hour_field = layer.text_fields.create!(ord: 64, name: "Service 1 Ending Hour OH1", code: 'service_1_ending_hour_oh1')
      .csd_organization("Org1").csd_service!("Service 1")
      .csd_operating_hours("OH1", Field::CSDApiConcern::csd_service_tag).csd_ending_hour!
    service_1_oh_1_begin_effective_date_field = layer.text_fields.create!(ord: 65, name: "Service 1Begin Effective OH1", code: 'service_1_begin_effective_oh1')
      .csd_organization("Org1").csd_service!("Service 1")
      .csd_operating_hours("OH1", Field::CSDApiConcern::csd_service_tag).csd_begin_effective_date!


    service_1_oh_2_open_flag_field = layer.yes_no_fields.create!(ord: 66, name: "Service 1 Operating Hour 2 Open Flag", code: 'service_1_open_flag_oh2')
        .csd_organization("Org1").csd_service!("Service 1")
        .csd_operating_hours("OH2", Field::CSDApiConcern::csd_service_tag)
        .csd_open_flag!
    service_1_oh_2_day_of_the_week_field = layer.numeric_fields.create!(ord: 67, name: "Service 1 Day of Week OH2", code: 'service_1_day_of_week_oh2')
      .csd_organization("Org1").csd_service!("Service 1")
      .csd_operating_hours("OH2", Field::CSDApiConcern::csd_service_tag).csd_day_of_the_week!
    service_1_oh_2_beginning_hour_field = layer.text_fields.create!(ord: 68, name: "Service 1Beginning Hour OH2", code: 'service_1_beginning_hour_oh2')
      .csd_organization("Org1").csd_service!("Service 1")
      .csd_operating_hours("OH2", Field::CSDApiConcern::csd_service_tag).csd_beginning_hour!
    service_1_oh_2_ending_hour_field = layer.text_fields.create!(ord: 69, name: "Service 1 Ending Hour OH2", code: 'service_1_ending_hour_oh2')
      .csd_organization("Org1").csd_service!("Service 1")
      .csd_operating_hours("OH2", Field::CSDApiConcern::csd_service_tag).csd_ending_hour!
    service_1_oh_2_begin_effective_date_field = layer.text_fields.create!(ord: 70, name: "Service 1 Begin Effective OH2", code: 'service_1_begin_effective_oh2')
      .csd_organization("Org1").csd_service!("Service 1")
      .csd_operating_hours("OH2", Field::CSDApiConcern::csd_service_tag).csd_begin_effective_date!

    service_1_oh_3_open_flag_field = layer.yes_no_fields.create!(ord: 71, name: "Service 1 Operating Hour 3 Open Flag", code: 'service_1_open_flag_oh3')
        .csd_organization("Org1").csd_service!("Service 1")
        .csd_operating_hours("OH3", Field::CSDApiConcern::csd_service_tag)
        .csd_open_flag!
    service_1_oh_3_day_of_the_week_field = layer.numeric_fields.create!(ord: 72, name: "Service 1 Day of Week OH3", code: 'service_1_day_of_week_oh3')
      .csd_organization("Org1").csd_service!("Service 1")
      .csd_operating_hours("OH3", Field::CSDApiConcern::csd_service_tag).csd_day_of_the_week!
    service_1_oh_3_beginning_hour_field = layer.text_fields.create!(ord: 73, name: "Service 1Beginning Hour OH3", code: 'service_1_beginning_hour_oh3')
      .csd_organization("Org1").csd_service!("Service 1")
      .csd_operating_hours("OH3", Field::CSDApiConcern::csd_service_tag).csd_beginning_hour!
    service_1_oh_3_ending_hour_field = layer.text_fields.create!(ord: 74, name: "Service 1 Ending Hour OH3", code: 'service_1_ending_hour_oh3')
      .csd_organization("Org1").csd_service!("Service 1")
      .csd_operating_hours("OH3", Field::CSDApiConcern::csd_service_tag).csd_ending_hour!
    service_1_oh_3_begin_effective_date_field = layer.text_fields.create!(ord: 75, name: "Service 1 Begin Effective OH3", code: 'service_1_begin_effective_oh3')
      .csd_organization("Org1").csd_service!("Service 1")
      .csd_operating_hours("OH3", Field::CSDApiConcern::csd_service_tag).csd_begin_effective_date!


    service_2_oh_1_open_flag_field = layer.yes_no_fields.create!(ord: 76, name: "Service 2 Operating Hour 1 Open Flag", code: 'service_2_open_flag_oh1')
        .csd_organization("Org1").csd_service!("Service 2")
        .csd_operating_hours("OH1", Field::CSDApiConcern::csd_service_tag)
        .csd_open_flag!
    service_2_oh_1_day_of_the_week_field = layer.numeric_fields.create!(ord: 77, name: "Service 2 Day of Week OH1", code: 'service_2_day_of_week_oh1')
      .csd_organization("Org1").csd_service!("Service 2")
      .csd_operating_hours("OH1", Field::CSDApiConcern::csd_service_tag).csd_day_of_the_week!
    service_2_oh_1_beginning_hour_field = layer.text_fields.create!(ord: 78, name: "Service 2Beginning Hour OH1", code: 'service_2_beginning_hour_oh1')
      .csd_organization("Org1").csd_service!("Service 2")
      .csd_operating_hours("OH1", Field::CSDApiConcern::csd_service_tag).csd_beginning_hour!
    service_2_oh_1_ending_hour_field = layer.text_fields.create!(ord: 79, name: "Service 2 Ending Hour OH1", code: 'service_2_ending_hour_oh1')
      .csd_organization("Org1").csd_service!("Service 2")
      .csd_operating_hours("OH1", Field::CSDApiConcern::csd_service_tag).csd_ending_hour!
    service_2_oh_1_begin_effective_date_field = layer.text_fields.create!(ord: 80, name: "Service 2 Begin Effective OH1", code: 'service_2_begin_effective_oh1')
      .csd_organization("Org1").csd_service!("Service 2")
      .csd_operating_hours("OH1", Field::CSDApiConcern::csd_service_tag).csd_begin_effective_date!


    service_2_oh_2_open_flag_field = layer.yes_no_fields.create!(ord: 81, name: "Service 2 Operating Hour 2 Open Flag", code: 'service_2_open_flag_oh2')
        .csd_organization("Org1").csd_service!("Service 2")
        .csd_operating_hours("OH2", Field::CSDApiConcern::csd_service_tag)
        .csd_open_flag!
    service_2_oh_2_day_of_the_week_field = layer.numeric_fields.create!(ord: 82, name: "Service 2 Day of Week OH2", code: 'service_2_day_of_week_oh2')
      .csd_organization("Org1").csd_service!("Service 2")
      .csd_operating_hours("OH2", Field::CSDApiConcern::csd_service_tag).csd_day_of_the_week!
    service_2_oh_2_beginning_hour_field = layer.text_fields.create!(ord: 83, name: "Service 2 Beginning Hour OH2", code: 'service_2_beginning_hour_oh2')
      .csd_organization("Org1").csd_service!("Service 2")
      .csd_operating_hours("OH2", Field::CSDApiConcern::csd_service_tag).csd_beginning_hour!
    service_2_oh_2_ending_hour_field = layer.text_fields.create!(ord: 84, name: "Service 2 Ending Hour OH2", code: 'service_2_ending_hour_oh2')
      .csd_organization("Org1").csd_service!("Service 2")
      .csd_operating_hours("OH2", Field::CSDApiConcern::csd_service_tag).csd_ending_hour!
    service_2_oh_2_begin_effective_date_field = layer.text_fields.create!(ord: 85, name: "Service 2 Begin Effective OH2", code: 'service_2_begin_effective_oh2')
      .csd_organization("Org1").csd_service!("Service 2")
      .csd_operating_hours("OH2", Field::CSDApiConcern::csd_service_tag).csd_begin_effective_date!

    service_2_oh_3_open_flag_field = layer.yes_no_fields.create!(ord: 86, name: "Service 2 Operating Hour 3 Open Flag", code: 'service_2_open_flag_oh3')
        .csd_organization("Org1").csd_service!("Service 2")
        .csd_operating_hours("OH3", Field::CSDApiConcern::csd_service_tag)
        .csd_open_flag!
    service_2_oh_3_day_of_the_week_field = layer.numeric_fields.create!(ord: 87, name: "Service 2 Day of Week OH3", code: 'service_2_day_of_week_oh3')
      .csd_organization("Org1").csd_service!("Service 2")
      .csd_operating_hours("OH3", Field::CSDApiConcern::csd_service_tag).csd_day_of_the_week!
    service_2_oh_3_beginning_hour_field = layer.text_fields.create!(ord: 88, name: "Service 2Beginning Hour OH3", code: 'service_2_beginning_hour_oh3')
      .csd_organization("Org1").csd_service!("Service 2")
      .csd_operating_hours("OH3", Field::CSDApiConcern::csd_service_tag).csd_beginning_hour!
    service_2_oh_3_ending_hour_field = layer.text_fields.create!(ord: 89, name: "Service 2 Ending Hour OH3", code: 'service_2_ending_hour_oh3')
      .csd_organization("Org1").csd_service!("Service 2")
      .csd_operating_hours("OH3", Field::CSDApiConcern::csd_service_tag).csd_ending_hour!
    service_2_oh_3_begin_effective_date_field = layer.text_fields.create!(ord: 92, name: "Service 2 Begin Effective OH3", code: 'service_2_begin_effective_oh3')
      .csd_organization("Org1").csd_service!("Service 2")
      .csd_operating_hours("OH3", Field::CSDApiConcern::csd_service_tag).csd_begin_effective_date!


    service_3_oh_1_open_flag_field = layer.yes_no_fields.create!(ord: 93, name: "Service 3 Operating Hour 1 Open Flag", code: 'service_3_open_flag_oh1')
        .csd_organization("Org1").csd_service!("Service 3")
        .csd_operating_hours("OH1", Field::CSDApiConcern::csd_service_tag)
        .csd_open_flag!
    service_3_oh_1_day_of_the_week_field = layer.numeric_fields.create!(ord: 94, name: "Service 3 Day of Week OH1", code: 'service_3_day_of_week_oh1')
      .csd_organization("Org1").csd_service!("Service 3")
      .csd_operating_hours("OH1", Field::CSDApiConcern::csd_service_tag).csd_day_of_the_week!
    service_3_oh_1_beginning_hour_field = layer.text_fields.create!(ord: 95, name: "Service 3 Beginning Hour OH1", code: 'service_3_beginning_hour_oh1')
      .csd_organization("Org1").csd_service!("Service 3")
      .csd_operating_hours("OH1", Field::CSDApiConcern::csd_service_tag).csd_beginning_hour!
    service_3_oh_1_ending_hour_field = layer.text_fields.create!(ord: 96, name: "Service 3 Ending Hour OH1", code: 'service_3_ending_hour_oh1')
      .csd_organization("Org1").csd_service!("Service 3")
      .csd_operating_hours("OH1", Field::CSDApiConcern::csd_service_tag).csd_ending_hour!
    service_3_oh_1_begin_effective_date_field = layer.text_fields.create!(ord: 97, name: "Service 3 Begin Effective OH1", code: 'service_3_begin_effective_oh1')
      .csd_organization("Org1").csd_service!("Service 3")
      .csd_operating_hours("OH1", Field::CSDApiConcern::csd_service_tag).csd_begin_effective_date!


    service_3_oh_2_open_flag_field = layer.yes_no_fields.create!(ord: 98, name: "Service 3 Operating Hour 2 Open Flag", code: 'service_3_open_flag_oh2')
        .csd_organization("Org1").csd_service!("Service 3")
        .csd_operating_hours("OH2", Field::CSDApiConcern::csd_service_tag)
        .csd_open_flag!
    service_3_oh_2_day_of_the_week_field = layer.numeric_fields.create!(ord: 99, name: "Service 3 Day of Week OH2", code: 'service_3_day_of_week_oh2')
      .csd_organization("Org1").csd_service!("Service 3")
      .csd_operating_hours("OH2", Field::CSDApiConcern::csd_service_tag).csd_day_of_the_week!
    service_3_oh_2_beginning_hour_field = layer.text_fields.create!(ord: 100, name: "Service 3 Beginning Hour OH2", code: 'service_3_beginning_hour_oh2')
      .csd_organization("Org1").csd_service!("Service 3")
      .csd_operating_hours("OH2", Field::CSDApiConcern::csd_service_tag).csd_beginning_hour!
    service_3_oh_2_ending_hour_field = layer.text_fields.create!(ord: 101, name: "Service 3 Ending Hour OH2", code: 'service_3_ending_hour_oh2')
      .csd_organization("Org1").csd_service!("Service 3")
      .csd_operating_hours("OH2", Field::CSDApiConcern::csd_service_tag).csd_ending_hour!
    service_3_oh_2_begin_effective_date_field = layer.text_fields.create!(ord: 102, name: "Service 3 Begin Effective OH2", code: 'service_3_begin_effective_oh2')
      .csd_organization("Org1").csd_service!("Service 3")
      .csd_operating_hours("OH2", Field::CSDApiConcern::csd_service_tag).csd_begin_effective_date!


    service_4_oh_2_open_flag_field = layer.yes_no_fields.create!(ord: 103, name: "Service 4 Operating Hour 2 Open Flag", code: 'service_4_open_flag_oh2')
        .csd_organization("Org1").csd_service!("Service 4")
        .csd_operating_hours("OH2", Field::CSDApiConcern::csd_service_tag)
        .csd_open_flag!
    service_4_oh_2_day_of_the_week_field = layer.numeric_fields.create!(ord: 104, name: "Service 4 Day of Week OH2", code: 'service_4_day_of_week_oh2')
      .csd_organization("Org1").csd_service!("Service 4")
      .csd_operating_hours("OH2", Field::CSDApiConcern::csd_service_tag).csd_day_of_the_week!
    service_4_oh_2_beginning_hour_field = layer.text_fields.create!(ord: 105, name: "Service 4 Beginning Hour OH2", code: 'service_4_beginning_hour_oh2')
      .csd_organization("Org1").csd_service!("Service 4")
      .csd_operating_hours("OH2", Field::CSDApiConcern::csd_service_tag).csd_beginning_hour!
    service_4_oh_2_ending_hour_field = layer.text_fields.create!(ord: 106, name: "Service 4 Ending Hour OH2", code: 'service_4_ending_hour_oh2')
      .csd_organization("Org1").csd_service!("Service 4")
      .csd_operating_hours("OH2", Field::CSDApiConcern::csd_service_tag).csd_ending_hour!
    service_4_oh_2_begin_effective_date_field = layer.text_fields.create!(ord: 107, name: "Service 4 Begin Effective OH2", code: 'service_4_begin_effective_oh2')
      .csd_organization("Org1").csd_service!("Service 4")
      .csd_operating_hours("OH2", Field::CSDApiConcern::csd_service_tag).csd_begin_effective_date!


   service_4_oh_1_open_flag_field = layer.yes_no_fields.create!(ord: 108, name: "Service 4 Operating Hour 1 Open Flag", code: 'service_4_open_flag_oh1')
        .csd_organization("Org1").csd_service!("Service 4")
        .csd_operating_hours("OH1", Field::CSDApiConcern::csd_service_tag)
        .csd_open_flag!
    service_4_oh_1_day_of_the_week_field = layer.numeric_fields.create!(ord: 109, name: "Service 4 Day of Week OH1", code: 'service_4_day_of_week_oh1')
      .csd_organization("Org1").csd_service!("Service 4")
      .csd_operating_hours("OH1", Field::CSDApiConcern::csd_service_tag).csd_day_of_the_week!
    service_4_oh_1_beginning_hour_field = layer.text_fields.create!(ord: 110, name: "Service 4 Beginning Hour OH1", code: 'service_4_beginning_hour_oh1')
      .csd_organization("Org1").csd_service!("Service 4")
      .csd_operating_hours("OH1", Field::CSDApiConcern::csd_service_tag).csd_beginning_hour!
    service_4_oh_1_ending_hour_field = layer.text_fields.create!(ord: 111, name: "Service 4 Ending Hour OH1", code: 'service_4_ending_hour_oh1')
      .csd_organization("Org1").csd_service!("Service 4")
      .csd_operating_hours("OH1", Field::CSDApiConcern::csd_service_tag).csd_ending_hour!
    service_4_oh_1_begin_effective_date_field = layer.text_fields.create!(ord: 112, name: "Service 4 Begin Effective OH1", code: 'service_4_begin_effective_oh1')
      .csd_organization("Org1").csd_service!("Service 4")
      .csd_operating_hours("OH1", Field::CSDApiConcern::csd_service_tag).csd_begin_effective_date!

    service_4_oh_3_open_flag_field = layer.yes_no_fields.create!(ord: 113, name: "Service 4 Operating Hour 3 Open Flag", code: 'service_4_open_flag_oh3')
        .csd_organization("Org1").csd_service!("Service 4")
        .csd_operating_hours("OH3", Field::CSDApiConcern::csd_service_tag)
        .csd_open_flag!
    service_4_oh_3_day_of_the_week_field = layer.numeric_fields.create!(ord: 114, name: "Service 4 Day of Week OH3", code: 'service_4_day_of_week_oh3')
      .csd_organization("Org1").csd_service!("Service 4")
      .csd_operating_hours("OH3", Field::CSDApiConcern::csd_service_tag).csd_day_of_the_week!
    service_4_oh_3_beginning_hour_field = layer.text_fields.create!(ord: 115, name: "Service 4 Beginning Hour OH3", code: 'service_4_beginning_hour_oh3')
      .csd_organization("Org1").csd_service!("Service 4")
      .csd_operating_hours("OH3", Field::CSDApiConcern::csd_service_tag).csd_beginning_hour!
    service_4_oh_3_ending_hour_field = layer.text_fields.create!(ord: 116, name: "Service 4 Ending Hour OH3", code: 'service_4_ending_hour_oh3')
      .csd_organization("Org1").csd_service!("Service 4")
      .csd_operating_hours("OH3", Field::CSDApiConcern::csd_service_tag).csd_ending_hour!
    service_4_oh_3_begin_effective_date_field = layer.text_fields.create!(ord: 117, name: "Service 4 Begin Effective OH3", code: 'service_4_begin_effective_oh3')
      .csd_organization("Org1").csd_service!("Service 4")
      .csd_operating_hours("OH3", Field::CSDApiConcern::csd_service_tag).csd_begin_effective_date!


    service_4_oh_4_open_flag_field = layer.yes_no_fields.create!(ord: 118, name: "Service 4 Operating Hour 4 Open Flag", code: 'service_4_open_flag_oh4')
        .csd_organization("Org1").csd_service!("Service 4")
        .csd_operating_hours("OH4", Field::CSDApiConcern::csd_service_tag)
        .csd_open_flag!
    service_4_oh_4_day_of_the_week_field = layer.numeric_fields.create!(ord: 119, name: "Service 4 Day of Week OH4", code: 'service_4_day_of_week_oh4')
      .csd_organization("Org1").csd_service!("Service 4")
      .csd_operating_hours("OH4", Field::CSDApiConcern::csd_service_tag).csd_day_of_the_week!
    service_4_oh_4_beginning_hour_field = layer.text_fields.create!(ord: 120, name: "Service 4 Beginning Hour OH4", code: 'service_4_beginning_hour_oh4')
      .csd_organization("Org1").csd_service!("Service 4")
      .csd_operating_hours("OH4", Field::CSDApiConcern::csd_service_tag).csd_beginning_hour!
    service_4_oh_4_ending_hour_field = layer.text_fields.create!(ord: 121, name: "Service 4 Ending Hour OH4", code: 'service_4_ending_hour_oh4')
      .csd_organization("Org1").csd_service!("Service 4")
      .csd_operating_hours("OH4", Field::CSDApiConcern::csd_service_tag).csd_ending_hour!
    service_4_oh_4_begin_effective_date_field = layer.text_fields.create!(ord: 122, name: "Service 4 Begin Effective OH4", code: 'service_4_begin_effective_oh4')
      .csd_organization("Org1").csd_service!("Service 4")
      .csd_operating_hours("OH4", Field::CSDApiConcern::csd_service_tag).csd_begin_effective_date!



    service_4_oh_5_open_flag_field = layer.yes_no_fields.create!(ord: 123, name: "Service 4 Operating Hour 5 Open Flag", code: 'service_4_open_flag_oh5')
        .csd_organization("Org1").csd_service!("Service 4")
        .csd_operating_hours("OH5", Field::CSDApiConcern::csd_service_tag)
        .csd_open_flag!
    service_4_oh_5_day_of_the_week_field = layer.numeric_fields.create!(ord: 124, name: "Service 4 Day of Week OH5", code: 'service_4_day_of_week_oh5')
      .csd_organization("Org1").csd_service!("Service 4")
      .csd_operating_hours("OH5", Field::CSDApiConcern::csd_service_tag).csd_day_of_the_week!
    service_4_oh_5_beginning_hour_field = layer.text_fields.create!(ord: 125, name: "Service 4 Beginning Hour OH5", code: 'service_4_beginning_hour_oh5')
      .csd_organization("Org1").csd_service!("Service 4")
      .csd_operating_hours("OH5", Field::CSDApiConcern::csd_service_tag).csd_beginning_hour!
    service_4_oh_5_ending_hour_field = layer.text_fields.create!(ord: 126, name: "Service 4 Ending Hour OH5", code: 'service_4_ending_hour_oh5')
      .csd_organization("Org1").csd_service!("Service 4")
      .csd_operating_hours("OH5", Field::CSDApiConcern::csd_service_tag).csd_ending_hour!
    service_4_oh_5_begin_effective_date_field = layer.text_fields.create!(ord: 127, name: "Service 4 Begin Effective OH5", code: 'service_4_begin_effective_oh5')
      .csd_organization("Org1").csd_service!("Service 4")
      .csd_operating_hours("OH5", Field::CSDApiConcern::csd_service_tag).csd_begin_effective_date!


    service_1_free_busy_uri = layer.text_fields.create!(ord: 128, name: "Service 1 free busy uri", code: "service_1_free_busy_uri")
      .csd_organization("Org1").csd_service!("Service 1").csd_free_busy_uri!

    service_2_free_busy_uri = layer.text_fields.create!(ord: 129, name: "Service 2 free busy uri", code: "service_2_free_busy_uri")
      .csd_organization("Org1").csd_service!("Service 2").csd_free_busy_uri!

    service_3_free_busy_uri = layer.text_fields.create!(ord: 130, name: "Service 3 free busy uri", code: "service_3_free_busy_uri")
            .csd_organization("Org1").csd_service!("Service 3").csd_free_busy_uri!

    service_4_free_busy_uri = layer.text_fields.create!(ord: 131, name: "Service 4 free busy uri", code: "service_4_free_busy_uri")
            .csd_organization("Org1").csd_service!("Service 4").csd_free_busy_uri!


    service_4_oh_6_open_flag_field = layer.yes_no_fields.create!(ord: 132, name: "Service 4 Operating Hour 6 Open Flag", code: 'service_4_open_flag_oh6')
        .csd_organization("Org1").csd_service!("Service 4")
        .csd_operating_hours("OH6", Field::CSDApiConcern::csd_service_tag)
        .csd_open_flag!
    service_4_oh_6_day_of_the_week_field = layer.numeric_fields.create!(ord: 133, name: "Service 4 Day of Week OH6", code: 'service_4_day_of_week_oh6')
      .csd_organization("Org1").csd_service!("Service 4")
      .csd_operating_hours("OH6", Field::CSDApiConcern::csd_service_tag).csd_day_of_the_week!
    service_4_oh_6_beginning_hour_field = layer.text_fields.create!(ord: 134, name: "Service 4 Beginning Hour OH6", code: 'service_4_beginning_hour_oh6')
      .csd_organization("Org1").csd_service!("Service 4")
      .csd_operating_hours("OH6", Field::CSDApiConcern::csd_service_tag).csd_beginning_hour!
    service_4_oh_6_ending_hour_field = layer.text_fields.create!(ord: 135, name: "Service 4 Ending Hour OH6", code: 'service_4_ending_hour_oh6')
      .csd_organization("Org1").csd_service!("Service 4")
      .csd_operating_hours("OH6", Field::CSDApiConcern::csd_service_tag).csd_ending_hour!
    service_4_oh_6_begin_effective_date_field = layer.text_fields.create!(ord: 136, name: "Service 4 Begin Effective OH6", code: 'service_4_begin_effective_oh6')
      .csd_organization("Org1").csd_service!("Service 4")
      .csd_operating_hours("OH6", Field::CSDApiConcern::csd_service_tag).csd_begin_effective_date!

    time_override = Time.iso8601("2014-12-01T14:00:00-00:00").to_s

    site_a = Site.create!(collection_id: collection.id, name: 'Connectathon Radiology Facility', lat: 35.05, lng: 106.60, user: user, created_at: time_override, updated_at: time_override,
      properties: {
        coded_type_medical_specialty.es_code => 1,
        entity_id_field.es_code => "e9964293-e169-4298-b4d0-ab07bf0cd78f",
        contact_1_common_name_field.es_code => "Anderson, Andrew",
        contact_1_forename_field.es_code => "Andrew",
        contact_1_surname_field.es_code => "Anderson",
        contact_1_street_address_field.es_code => "2222 19th Ave SW",
        contact_1_city_field.es_code => "Santa Fe",
        contact_1_state_province_field.es_code => "NM",
        contact_1_country_field.es_code => "USA",
        contact_1_postal_code_field.es_code => "87124",

        contact_2_common_name_field.es_code => "Juarez, Julio",
        contact_2_forename_field.es_code => "Julio",
        contact_2_surname_field.es_code => "Juarez",
        contact_2_street_address_field.es_code => "2222 19th Ave SW",
        contact_2_city_field.es_code => "Santa Fe",
        contact_2_state_province_field.es_code => "NM",
        contact_2_country_field.es_code => "USA",
        contact_2_postal_code_field.es_code => "87124",

        language_1_field.es_code => 1,
        language_2_field.es_code => 2,

        oh_1_open_flag_field.es_code => true,
        oh_1_day_of_the_week_field.es_code => 1,
        oh_1_beginning_hour_field.es_code => '08:00:00',
        oh_1_ending_hour_field.es_code => '18:00:00',
        oh_1_begin_effective_date_field.es_code => '2014-12-01',

        oh_2_open_flag_field.es_code => true,
        oh_2_day_of_the_week_field.es_code => 2,
        oh_2_beginning_hour_field.es_code => '13:00:00',
        oh_2_ending_hour_field.es_code => '17:00:00',
        oh_2_begin_effective_date_field.es_code => '2014-12-01',

        oh_3_open_flag_field.es_code => true,
        oh_3_day_of_the_week_field.es_code => 3,
        oh_3_beginning_hour_field.es_code => '09:00:00',
        oh_3_ending_hour_field.es_code => '17:00:00',
        oh_3_begin_effective_date_field.es_code => '2014-12-01',

        oh_4_open_flag_field.es_code => true,
        oh_4_day_of_the_week_field.es_code => 4,
        oh_4_beginning_hour_field.es_code => '13:00:00',
        oh_4_ending_hour_field.es_code => '17:00:00',
        oh_4_begin_effective_date_field.es_code => '2014-12-01',

        oh_5_open_flag_field.es_code => true,
        oh_5_day_of_the_week_field.es_code => 5,
        oh_5_beginning_hour_field.es_code => '09:00:00',
        oh_5_ending_hour_field.es_code => '17:00:00',
        oh_5_begin_effective_date_field.es_code => '2013-12-01',

        billing_address_street_field.es_code => "1234 Cactus Way",
        billing_address_city_field.es_code => 'Santa Fe',
        billing_address_state_field.es_code => "NM",
        billing_address_country_field.es_code => "USA",
        billing_address_postal_code_field.es_code => "87501",

        practice_address_street_field.es_code => "2222 19th Ave SW",
        practice_address_city_field.es_code => 'Santa Fe',
        practice_address_state_field.es_code => "NM",
        practice_address_country_field.es_code => "USA",
        practice_address_postal_code_field.es_code => "87124",

        organization_1_field.es_code => "08c3286e-2163-462c-b77f-1f431d7351ab",

        service_1_field.es_code => "3c43ed80-b323-4f31-b450-57ce5923fc85",
        service_1_name_field.es_code => "Connectathon Radiation Therapy",
        service_1_language_field.es_code => 1,
        service_1_free_busy_uri.es_code => "http://tbd/free/busy/facilities",

        service_1_oh_1_open_flag_field.es_code => true,
        service_1_oh_1_day_of_the_week_field.es_code => 1,
        service_1_oh_1_beginning_hour_field.es_code => '09:00:00',
        service_1_oh_1_ending_hour_field.es_code => '12:00:00',
        service_1_oh_1_begin_effective_date_field.es_code => '2014-12-01',

        service_1_oh_2_open_flag_field.es_code => true,
        service_1_oh_2_day_of_the_week_field.es_code => 3,
        service_1_oh_2_beginning_hour_field.es_code => '09:00:00',
        service_1_oh_2_ending_hour_field.es_code => '12:00:00',
        service_1_oh_2_begin_effective_date_field.es_code => '2014-12-01',

        service_1_oh_3_open_flag_field.es_code => true,
        service_1_oh_3_day_of_the_week_field.es_code => 5,
        service_1_oh_3_beginning_hour_field.es_code => '09:00:00',
        service_1_oh_3_ending_hour_field.es_code => '12:00:00',
        service_1_oh_3_begin_effective_date_field.es_code => '2014-12-01',

        service_2_field.es_code => "def4c912-46ae-4e23-a78c-80ea597a82ee",
        service_2_name_field.es_code => "Connectathon Women's Imaging Service",
        service_2_language_field.es_code => 1,
        service_2_free_busy_uri.es_code => "http://tbd/free/busy/facilities",

        service_2_oh_1_open_flag_field.es_code => true,
        service_2_oh_1_day_of_the_week_field.es_code => 1,
        service_2_oh_1_beginning_hour_field.es_code => '13:00:00',
        service_2_oh_1_ending_hour_field.es_code => '17:00:00',
        service_2_oh_1_begin_effective_date_field.es_code => '2014-12-01',

        service_2_oh_2_open_flag_field.es_code => true,
        service_2_oh_2_day_of_the_week_field.es_code => 3,
        service_2_oh_2_beginning_hour_field.es_code => '13:00:00',
        service_2_oh_2_ending_hour_field.es_code => '17:00:00',
        service_2_oh_2_begin_effective_date_field.es_code => '2014-12-01',

        service_2_oh_3_open_flag_field.es_code => true,
        service_2_oh_3_day_of_the_week_field.es_code => 5,
        service_2_oh_3_beginning_hour_field.es_code => '13:00:00',
        service_2_oh_3_ending_hour_field.es_code => '17:00:00',
        service_2_oh_3_begin_effective_date_field.es_code => '2014-12-01',

        service_3_field.es_code => "def4c912-46ae-4e23-a78c-80ea597a82ee",
        service_3_name_field.es_code => "Connectathon Servicio de Radiologica de la Mujer",
        service_3_language_field.es_code => 2,
        service_3_free_busy_uri.es_code => "http://tbd/free/busy/facilities",

        service_3_oh_1_open_flag_field.es_code => true,
        service_3_oh_1_day_of_the_week_field.es_code => 2,
        service_3_oh_1_beginning_hour_field.es_code => '13:00:00',
        service_3_oh_1_ending_hour_field.es_code => '17:00:00',
        service_3_oh_1_begin_effective_date_field.es_code => '2014-12-01',

        service_3_oh_2_open_flag_field.es_code => true,
        service_3_oh_2_day_of_the_week_field.es_code => 4,
        service_3_oh_2_beginning_hour_field.es_code => '13:00:00',
        service_3_oh_2_ending_hour_field.es_code => '17:00:00',
        service_3_oh_2_begin_effective_date_field.es_code => '2014-12-01',

        service_4_field.es_code => "97f25cbb-d1dd-4849-b369-f8d7c35f7775",
        service_4_name_field.es_code => "Connectathon Screening X-ray",
        service_4_language_field.es_code => 1,
        service_4_free_busy_uri.es_code => "http://tbd/free/busy/facilities",

        service_4_oh_1_open_flag_field.es_code => true,
        service_4_oh_1_day_of_the_week_field.es_code => 1,
        service_4_oh_1_beginning_hour_field.es_code => '08:00:00',
        service_4_oh_1_ending_hour_field.es_code => '18:00:00',
        service_4_oh_1_begin_effective_date_field.es_code => '2014-12-01',

        service_4_oh_2_open_flag_field.es_code => true,
        service_4_oh_2_day_of_the_week_field.es_code => 2,
        service_4_oh_2_beginning_hour_field.es_code => '08:00:00',
        service_4_oh_2_ending_hour_field.es_code => '18:00:00',
        service_4_oh_2_begin_effective_date_field.es_code => '2014-12-01',

        service_4_oh_3_open_flag_field.es_code => true,
        service_4_oh_3_day_of_the_week_field.es_code => 3,
        service_4_oh_3_beginning_hour_field.es_code => '08:00:00',
        service_4_oh_3_ending_hour_field.es_code => '18:00:00',
        service_4_oh_3_begin_effective_date_field.es_code => '2014-12-01',

        service_4_oh_4_open_flag_field.es_code => true,
        service_4_oh_4_day_of_the_week_field.es_code => 4,
        service_4_oh_4_beginning_hour_field.es_code => '08:00:00',
        service_4_oh_4_ending_hour_field.es_code => '18:00:00',
        service_4_oh_4_begin_effective_date_field.es_code => '2014-12-01',

        service_4_oh_5_open_flag_field.es_code => true,
        service_4_oh_5_day_of_the_week_field.es_code => 5,
        service_4_oh_5_beginning_hour_field.es_code => '08:00:00',
        service_4_oh_5_ending_hour_field.es_code => '18:00:00',
        service_4_oh_5_begin_effective_date_field.es_code => '2014-12-01',

        service_4_oh_6_open_flag_field.es_code => true,
        service_4_oh_6_day_of_the_week_field.es_code => 6,
        service_4_oh_6_beginning_hour_field.es_code => '08:00:00',
        service_4_oh_6_ending_hour_field.es_code => '18:00:00',
        service_4_oh_6_begin_effective_date_field.es_code => '2014-12-01',
      })

    site_b = Site.create!(collection_id: collection.id, name: 'Connectathon Dialysis Facility One', lat: 35.05, lng: 106.60, user: user, created_at: time_override, updated_at: time_override,
      properties: {
        coded_type_medical_specialty.es_code => 2,
        entity_id_field.es_code => "a3eb03db-0094-4059-9156-8de081cb5885",
        contact_1_common_name_field.es_code => "Benson, Barbara",
        contact_1_forename_field.es_code => "Barbara",
        contact_1_surname_field.es_code => "Benson",
        contact_1_street_address_field.es_code => "2222 19th Ave SW",
        contact_1_city_field.es_code => "Santa Fe",
        contact_1_state_province_field.es_code => "NM",
        contact_1_country_field.es_code => "USA",
        contact_1_postal_code_field.es_code => "87124",

        contact_2_common_name_field.es_code => "Martinez, Ruby",
        contact_2_forename_field.es_code => "Ruby",
        contact_2_surname_field.es_code => "Martinez",
        contact_2_street_address_field.es_code => "2222 19th Ave SW",
        contact_2_city_field.es_code => "Santa Fe",
        contact_2_state_province_field.es_code => "NM",
        contact_2_country_field.es_code => "USA",
        contact_2_postal_code_field.es_code => "87124",

        language_1_field.es_code => 1,
        language_2_field.es_code => 2,

        oh_1_open_flag_field.es_code => true,
        oh_1_day_of_the_week_field.es_code => 1,
        oh_1_beginning_hour_field.es_code => '08:00:00',
        oh_1_ending_hour_field.es_code => '17:00:00',
        oh_1_begin_effective_date_field.es_code => '2014-12-01',

        oh_5_open_flag_field.es_code => true,
        oh_5_day_of_the_week_field.es_code => 5,
        oh_5_beginning_hour_field.es_code => '05:00:00',
        oh_5_ending_hour_field.es_code => '17:00:00',
        oh_5_begin_effective_date_field.es_code => '2013-12-01',

        billing_address_street_field.es_code => "1234 Cactus Way",
        billing_address_city_field.es_code => 'Santa Fe',
        billing_address_state_field.es_code => "NM",
        billing_address_country_field.es_code => "USA",
        billing_address_postal_code_field.es_code => "87501",

        practice_address_street_field.es_code => "2222 19th Ave SW",
        practice_address_city_field.es_code => 'Rio Rancho',
        practice_address_state_field.es_code => "NM",
        practice_address_country_field.es_code => "USA",
        practice_address_postal_code_field.es_code => "87124",

        organization_1_field.es_code => "08c3286e-2163-462c-b77f-1f431d7351ab",

        service_1_field.es_code => "9f45a9bd-f360-4f5a-9f39-a04f19720424",
        service_1_name_field.es_code => "Connectathon Dialysis Service",
        service_1_language_field.es_code => 1,
        service_1_free_busy_uri.es_code => "http://tbd/free/busy/facilities",

        service_1_oh_1_open_flag_field.es_code => true,
        service_1_oh_1_day_of_the_week_field.es_code => 1,
        service_1_oh_1_beginning_hour_field.es_code => '09:00:00',
        service_1_oh_1_ending_hour_field.es_code => '17:00:00',
        service_1_oh_1_begin_effective_date_field.es_code => '2014-12-01',

        service_1_oh_2_open_flag_field.es_code => true,
        service_1_oh_2_day_of_the_week_field.es_code => 2,
        service_1_oh_2_beginning_hour_field.es_code => '09:00:00',
        service_1_oh_2_ending_hour_field.es_code => '17:00:00',
        service_1_oh_2_begin_effective_date_field.es_code => '2014-12-01',

        service_1_oh_3_open_flag_field.es_code => true,
        service_1_oh_3_day_of_the_week_field.es_code => 3,
        service_1_oh_3_beginning_hour_field.es_code => '09:00:00',
        service_1_oh_3_ending_hour_field.es_code => '17:00:00',
        service_1_oh_3_begin_effective_date_field.es_code => '2014-12-01',

        service_2_field.es_code => "9f45a9bd-f360-4f5a-9f39-a04f19720424",
        service_2_name_field.es_code => "Connectathon Diálisis Servicio",
        service_2_language_field.es_code => 2,
        service_2_free_busy_uri.es_code => "http://tbd/free/busy/facilities",

        service_2_oh_1_open_flag_field.es_code => true,
        service_2_oh_1_day_of_the_week_field.es_code => 4,
        service_2_oh_1_beginning_hour_field.es_code => '09:00:00',
        service_2_oh_1_ending_hour_field.es_code => '17:00:00',
        service_2_oh_1_begin_effective_date_field.es_code => '2015-01-01',

        service_2_oh_2_open_flag_field.es_code => true,
        service_2_oh_2_day_of_the_week_field.es_code => 5,
        service_2_oh_2_beginning_hour_field.es_code => '09:00:00',
        service_2_oh_2_ending_hour_field.es_code => '17:00:00',
        service_2_oh_2_begin_effective_date_field.es_code => '2015-01-01',
      })

    site_c = Site.create!(collection_id: collection.id, name: 'Connectathon Dialysis Facility Two', lat: 34.5441, lng: 122.4717, user: user, created_at: time_override, updated_at: time_override,
      properties: {
        coded_type_medical_specialty.es_code => 2,
        entity_id_field.es_code => "be4d27c3-21b8-481f-9fed-6524a8eb9bac",
        contact_1_common_name_field.es_code => "Robertson, Robert",
        contact_1_forename_field.es_code => "Robert",
        contact_1_surname_field.es_code => "Robertson",
        contact_1_street_address_field.es_code => "2222 19th Ave SW",
        contact_1_city_field.es_code => "Santa Fe",
        contact_1_state_province_field.es_code => "NM",
        contact_1_country_field.es_code => "USA",
        contact_1_postal_code_field.es_code => "87124",

        contact_2_common_name_field.es_code => "Juarez, Angel",
        contact_2_forename_field.es_code => "Angel",
        contact_2_surname_field.es_code => "Juarez",
        contact_2_street_address_field.es_code => "2222 19th Ave SW",
        contact_2_city_field.es_code => "Santa Fe",
        contact_2_state_province_field.es_code => "NM",
        contact_2_country_field.es_code => "USA",
        contact_2_postal_code_field.es_code => "87124",

        language_1_field.es_code => 1,
        language_2_field.es_code => 2,

        oh_1_open_flag_field.es_code => true,
        oh_1_day_of_the_week_field.es_code => 1,
        oh_1_beginning_hour_field.es_code => '08:00:00',
        oh_1_ending_hour_field.es_code => '17:00:00',
        oh_1_begin_effective_date_field.es_code => '2014-12-01',

        oh_5_open_flag_field.es_code => true,
        oh_5_day_of_the_week_field.es_code => 5,
        oh_5_beginning_hour_field.es_code => '05:00:00',
        oh_5_ending_hour_field.es_code => '17:00:00',
        oh_5_begin_effective_date_field.es_code => '2014-12-01',

        billing_address_street_field.es_code => "434 W. Gurley Street",
        billing_address_city_field.es_code => 'Prescott',
        billing_address_state_field.es_code => "AZ",
        billing_address_country_field.es_code => "USA",
        billing_address_postal_code_field.es_code => "86301",

        practice_address_street_field.es_code => "434 W. Gurley Street",
        practice_address_city_field.es_code => 'Prescott',
        practice_address_state_field.es_code => "AZ",
        practice_address_country_field.es_code => "USA",
        practice_address_postal_code_field.es_code => "86301",

        organization_1_field.es_code => "08c3286e-2163-462c-b77f-1f431d7351ab",

        service_1_field.es_code => "9f45a9bd-f360-4f5a-9f39-a04f19720424",
        service_1_name_field.es_code => "Connectathon Diálisis Servicio",
        service_1_language_field.es_code => 2,

        service_1_oh_1_open_flag_field.es_code => true,
        service_1_oh_1_day_of_the_week_field.es_code => 5,
        service_1_oh_1_beginning_hour_field.es_code => '09:00:00',
        service_1_oh_1_ending_hour_field.es_code => '17:00:00',
        service_1_oh_1_begin_effective_date_field.es_code => '2014-12-01',

        service_4_field.es_code => "9f45a9bd-f360-4f5a-9f39-a04f19720424",
        service_4_name_field.es_code => "Connectathon Dialysis Service",
        service_4_language_field.es_code => 1,

        service_4_oh_1_open_flag_field.es_code => true,
        service_4_oh_1_day_of_the_week_field.es_code => 1,
        service_4_oh_1_beginning_hour_field.es_code => '09:00:00',
        service_4_oh_1_ending_hour_field.es_code => '17:00:00',
        service_4_oh_1_begin_effective_date_field.es_code => '2014-12-01',

        service_4_oh_2_open_flag_field.es_code => true,
        service_4_oh_2_day_of_the_week_field.es_code => 2,
        service_4_oh_2_beginning_hour_field.es_code => '09:00:00',
        service_4_oh_2_ending_hour_field.es_code => '17:00:00',
        service_4_oh_2_begin_effective_date_field.es_code => '2014-12-01',

        service_4_oh_3_open_flag_field.es_code => true,
        service_4_oh_3_day_of_the_week_field.es_code => 3,
        service_4_oh_3_beginning_hour_field.es_code => '09:00:00',
        service_4_oh_3_ending_hour_field.es_code => '17:00:00',
        service_4_oh_3_begin_effective_date_field.es_code => '2013-12-01',

        service_4_oh_4_open_flag_field.es_code => true,
        service_4_oh_4_day_of_the_week_field.es_code => 4,
        service_4_oh_4_beginning_hour_field.es_code => '09:00:00',
        service_4_oh_4_ending_hour_field.es_code => '17:00:00',
        service_4_oh_4_begin_effective_date_field.es_code => '2014-12-01',

        service_4_oh_5_open_flag_field.es_code => true,
        service_4_oh_5_day_of_the_week_field.es_code => 5,
        service_4_oh_5_beginning_hour_field.es_code => '09:00:00',
        service_4_oh_5_ending_hour_field.es_code => '17:00:00',
        service_4_oh_5_begin_effective_date_field.es_code => '2014-12-01',

        service_4_oh_6_open_flag_field.es_code => true,
        service_4_oh_6_day_of_the_week_field.es_code => 6,
        service_4_oh_6_beginning_hour_field.es_code => '09:00:00',
        service_4_oh_6_ending_hour_field.es_code => '17:00:00',
        service_4_oh_6_begin_effective_date_field.es_code => '2014-12-01',

      })
  end

  def self.generate(owner)
    collection = Collection.create! name: "CSD #{Time.now}", icon: "default"
    collection = owner.create_collection collection
    fill collection
  end
end
