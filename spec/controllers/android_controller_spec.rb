require 'spec_helper'

describe AndroidController do
  include Devise::TestHelpers
  let!(:user) { User.make }
  let!(:collection1) { user.create_collection(Collection.make_unsaved) }
  let!(:collection2) { user.create_collection(Collection.make_unsaved) }
  let!(:layer) { collection1.layers.make }

  let!(:text) { layer.fields.make :code => 'text', :kind => 'text' }
  let!(:numeric) { layer.fields.make :code => 'numeric', :kind => 'numeric' }

  before(:each) {sign_in user}

  describe "Get JSON collections" do
    before(:each) do
      get :collections_json
    end

    it { response.should be_success }
    it "should response in JSON format" do
      response.content_type.should eq 'application/json'
    end

  end

  describe "helper methods" do
    context "Render Xform" do
      before(:each) do
        @result = controller.render_xform(collection1)

      end
      it "should render Xform's title with collection's name" do
        @result.should match(/<h:title>#{collection1.name}<\/h:title>/)
      end
      it "should render collection id in the xform's model" do
        @result.should match(/<id type=\"integer\">#{collection1.id}<\/id>/)
      end
      it "should render the model elements for existing fields in the xform's model" do
        text_field = /<field-#{text.id}><field-id>#{text.id}<\/field-id><value \/><\/field-#{text.id}>/
        numeric_field = /<field-#{numeric.id}><field-id>#{numeric.id}<\/field-id><value \/><\/field-#{numeric.id}>/
        fields = /#{text_field}#{numeric_field}/
        @result.should match(fields)
      end
      it "should render the binding elements for existing fields in the xform's model" do
        text_field = /<bind nodeset=\"\/resource\/existing-fields\/field-#{text.id}\/value\" \/>/
        numeric_field = /<bind nodeset=\"\/resource\/existing-fields\/field-#{numeric.id}\/value\" \/>/
        fields = /#{text_field}#{numeric_field}/
        @result.should match(fields)
      end
      it "should render the ui elements for existing fields in the xform's body" do
        text_field = /<input ref=\"\/resource\/existing-fields\/field-#{text.id}\/value\"><label>#{text.name}<\/label><\/input>/
        numeric_field = /<input ref=\"\/resource\/existing-fields\/field-#{numeric.id}\/value\"><label>#{numeric.name}<\/label><\/input>/
        fields = /#{text_field}#{numeric_field}/
        @result.should match(fields)
     end
    end
  end
end
