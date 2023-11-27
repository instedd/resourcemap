require 'spec_helper'

describe AndroidController, :type => :controller do
  include Devise::TestHelpers

  let(:user) { User.make }
  let!(:collection1) { user.create_collection(Collection.make_unsaved) }
  let!(:collection2) { user.collections.make }
  let(:layer) { collection1.layers.make }

  let!(:text) { layer.text_fields.make :code => 'text' }
  let!(:numeric) { layer.numeric_fields.make :code => 'numeric'}

  before(:each) {sign_in user}

  describe "Get JSON collections" do
    before(:each) do
      get :collections_json
    end

    it { expect(response).to be_success }

    it "should response in JSON format" do
      expect(response.content_type).to eq 'application/json'
    end
  end

  describe "submission" do
    before(:each) do
      @xml = "<?xml version='1.0' ?>
      <site>
        <collection-id type='integer'>%(:collection_id)<\/collection-id>
        <name>Cambodiana<\/name>
        <lat type='float'>11.53<\/lat>
        <lng type='float'>104.93<\/lng>
        <existing-fields>
          <field-#{text.id}>
            <field-id>#{text.id}<\/field-id>
            <value>Who know?<\/value>
          <\/field-#{text.id}>
          <field-#{numeric.id}>
            <field-id>#{numeric.id}<\/field-id>
            <value>10<\/value>
          <\/field-#{numeric.id}>
        <\/existing-fields>
      <\/site>"
    end

    it "should post submission" do
      @xml = @xml.gsub("%(:collection_id)",collection1.id.to_s)
      File.open("spec/fixtures/instant_file.xml","w") { |f| f.puts @xml }
      xml_file = fixture_file_upload('/instant_file.xml', 'text/xml')

      post :submission, :xml_submission_file => xml_file
      expect(response).to be_success
    end

    it "should response Unauthorized if user is not an admin" do
      @xml = @xml.gsub("%(:collection_id)",collection2.id.to_s)
      File.open("spec/fixtures/instant_file.xml","w") { |f| f.puts @xml }
      xml_file = fixture_file_upload('/instant_file.xml', 'text/xml')

      post :submission, :xml_submission_file => xml_file
      expect(response.response_code).to eq(401)
      expect(response).not_to be_success
    end
  end

  describe "helper methods" do
    context "Render Xform" do
      before(:each) do
        @result = controller.render_xform(collection1)
      end

      it "should render Xform's title with collection's name" do
        expect(@result).to match(/<h:title>#{collection1.name}<\/h:title>/)
      end

      it "should render collection id in the xform's model" do
        expect(@result).to match(/<collection-id type=\"integer\">#{collection1.id}<\/collection-id>/)
      end

      it "should render the model elements for existing fields in the xform's model" do
        text_field = /<field-#{text.id}><field-id>#{text.id}<\/field-id><value \/><\/field-#{text.id}>/
        numeric_field = /<field-#{numeric.id}><field-id>#{numeric.id}<\/field-id><value \/><\/field-#{numeric.id}>/
        fields = /#{text_field}#{numeric_field}/
        expect(@result).to match(fields)
      end

      it "should render the binding elements for existing fields in the xform's model" do
        text_field = /<bind nodeset=\"\/site\/existing-fields\/field-#{text.id}\/value\" \/>/
        numeric_field = /<bind nodeset=\"\/site\/existing-fields\/field-#{numeric.id}\/value\" \/>/
        fields = /#{text_field}#{numeric_field}/
        expect(@result).to match(fields)
      end

      it "should render the ui elements for existing fields in the xform's body" do
        text_field = /<input ref=\"\/site\/existing-fields\/field-#{text.id}\/value\"><label>#{text.name}<\/label><\/input>/
        numeric_field = /<input ref=\"\/site\/existing-fields\/field-#{numeric.id}\/value\"><label>#{numeric.name}<\/label><\/input>/
        fields = /#{text_field}#{numeric_field}/
        expect(@result).to match(fields)
      end
    end
  end
end
