class AndroidController < ApplicationController
  before_filter :authenticate_user!
  helper_method :render_xform

  ODKFORM_TEMPLATE = "public/odk_form_template.xml"
 
  def collections_json
    collection_array=[]
    collections.all.each do |collection|
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

end
