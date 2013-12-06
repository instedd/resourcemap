class CsdApiController < ApplicationController
  before_filter :authenticate_user_without_guisso!

  Mime::Type.register "application/wsdl+xml", :wsdl
  Mime::Type.unregister :xml
  Mime::Type.register "text/xml", :xml

  skip_before_filter :verify_authenticity_token

  authorize_resource :collection, :decent_exposure => true

  rescue_from Exception, :with => :rescue_error

  def index
  end

  def get_directory_modifications
    # Parse message
    soap_message = Nokogiri::XML(request.body.read)

    # Validation
    soap_body = extract_soap_body(soap_message)
    validate_soap_body(soap_body)

    # Create the search object and apply updated_since filter
    search = collection.new_search current_user_id: current_user.id
    search.use_codes_instead_of_es_codes
    search.unlimited
    updated_since = soap_message.xpath('//soap:Body//csd:lastModified').children.first.content
    search.after(updated_since)

    @facilities = search.api_results
    @request_id = soap_message.xpath("//soap:Header/wsa:MessageID").children.first.content
    @collection = collection

    render template: 'directories', formats: [:xml], handler: :builder, layout: false
  end

  private

  def rescue_error(ex)
    status = case ex
      when ActionController::RoutingError then 404
      when ActiveRecord::RecordNotFound then 404
      when ActiveRecord::RecordInvalid then 400
      when CanCan::AccessDenied then 403
      else 500
    end

    # If any exception was raised generate a SOAP fault, if there is no
    # fault_code present then default to fault_code Server (indicating the
    # message failed due to an error on the server)
    @fault_code = ex.respond_to?(:fault_code) ? ex.fault_code : "Server"
    @fault_string = ex.message

    render template: 'fault', formats: [:xml], handlers: :builder, layout: false, :status => status
  end

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
