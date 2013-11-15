class CsdApiController < ApplicationController
  Mime::Type.register "application/wsdl+xml", :wsdl
  Mime::Type.unregister :xml
  Mime::Type.register "text/xml", :xml

  skip_before_filter :verify_authenticity_token

  before_filter :authenticate_user!

  def directories
    # Parse message
    soap_message = Nokogiri::XML(request.body.read)

    # Validation
    soap_body = extract_soap_body(soap_message)
    validate_soap_body(soap_body)

    # TODO: Load lastModified datetime

    search = collection.new_search current_user_id: current_user.id

    search.use_codes_instead_of_es_codes
    search.unlimited
    #search.sort "updated_since", false
    @facities = search.api_results

    render template: 'directories', formats: [:xml], handler: :builder, layout: false

  rescue StandardError => e
    # If any exception was raised generate a SOAP fault, if there is no
    # fault_code present then default to fault_code Server (indicating the
    # message failed due to an error on the server)
    @fault_code = e.respond_to?(:fault_code) ? e.fault_code : "Server"
    @fault_string = e.message

    render template: 'fault', formats: [:xml], handlers: :builder, layout: false, :status => 500
  end

  private

  def extract_soap_body(soap_message)
    # Extract the SOAP body from SOAP envelope using XSLT
    xslt = Nokogiri::XSLT(File.read("#{Rails.root}/plugins/csd_api/request_stylesheet.xslt"))
    xslt.transform(soap_message)
  end

  def validate_soap_body(soap_body)
    # Validate the content of the SOAP body using the XML schema that is used
    # within the WSDL
    xsd = Nokogiri::XML::Schema(File.read("#{Rails.root}/plugins/csd_api/csd.xml"))
    errors = xsd.validate(soap_body).map{|e| e.message}.join(", ")
    # If the content of the SOAP body does not validate generate a SOAP fault
    # with fault_code Client (indicating the message failed due to a client
    # error)
    raise(SoapFault::ClientError, errors) unless errors == ""
  end

end
