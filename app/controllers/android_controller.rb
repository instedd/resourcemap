class AndroidController < ApplicationController
  protect_from_forgery :except => :submission
  before_action :authenticate_user!
  helper_method :render_xform, :get_hash_from_xml, :prepare_site

  expose(:collections) { Collection.accessible_by(current_ability) }


  ODKFORM_TEMPLATE = "public/odk_form_template.xml"

  def collections_json
    collection_array=[]
    collections.each do |collection|
      collection_hash = collection.attributes
      collection_hash["form"] = render_xform(collection)
      collection_array.push collection_hash
    end
    render :json => collection_array
  end

  def render_xform(collection)
    if File.exist? ODKFORM_TEMPLATE
      File.open ODKFORM_TEMPLATE, "r" do |file|
        xform = Xform.new(file.read)
        xform.render_form(collection)
      end
    else
      ""
    end
  end

  def submission
    xml_hash = HashParser.from_xml_file(params["xml_submission_file"]).values.first.merge("current_user" => current_user)
    if current_user.admins?(Collection.find(xml_hash["collection_id"]))
      render_json Site.create_or_update_from_hash!(xml_hash)
    else
      render plain: "User is unauthorized", status: 401
    end
  end

end
