require 'spec_helper'

describe NuntiumController, :type => :controller do
  describe "POST 'receive'" do
    before(:each) do
      @collection = Collection.make!(:name => 'Healt Center')
      @layer = @collection.layers.make!(:name => "default")
      @user = User.make!(:phone_number => '85512345678')
      f1 = @layer.numeric_fields.make!(:id => 10, :name => "Ambulance", :code => "AB", :ord => 1)
      f2 = @layer.numeric_fields.make!(:id => 11, :name => "Doctor", :code => "DO", :ord => 2)
      membership = @collection.memberships.create(:user => @user, :admin => false)
      membership.layer_memberships.create(:layer_id => @layer.id, :read => true, :write => true)
      site = @collection.sites.make!(:name => "SiemReap Health Center", :lat => 9, :lng => 9, :id_with_prefix => "AA1", :properties => {"10"=>5, "11"=>2})
      @params = { :guid => "123", :from => "sms://85512345678", :body => "dyrm u AA1 AB=2" }
      @message = Message.create(@params)
    end

    it "should save message" do
      expect(Message).to receive(:create!).with(:guid => "123", :from => "sms://85512345678", :body => "dyrm u AA1 AB=2").and_return(@message)
      post :receive, @params
    end

    describe "should validate post data" do
      def post_receive_without(param)
        post :receive, @params.clone.delete_if { |k, v| k == param }
      end

      it "should response error" do
        post :receive
        expect(response.response_code).to eq(400)
      end

      it "should check for guid" do
        post_receive_without :guid
        expect(response.body).to match /Validation failed: Guid can't be blank/
      end

      it "should check for from" do
        post_receive_without :from
        expect(response.body).to match /Validation failed: From can't be blank/
      end

      it "should check for body" do
        post_receive_without :body
        expect(response.body).to match /Validation failed: Body can't be blank/
      end
    end
    describe "message processing" do
      before(:each) do
        @message = Message.create @params
        expect(controller).to receive(:save_message).and_return(@message)
      end

      it "should process message" do
        post :receive, @params
        expect(response.response_code).to eq(200)
      end

      it "should response plain text" do
        post :receive, @params
        expect(response.content_type).to eq("text/plain")
      end
    end
  end

  describe "authenticate" do
    it "should authenticate via http basic authentication" do
      post :authenticate
      expect(response.response_code).to eq(401)
    end

    it "should response unauthorized for bad user" do
      request.env["HTTP_AUTHORIZATION"] = ActionController::HttpAuthentication::Basic.encode_credentials("foo", "secret")
      post :authenticate
      expect(response.response_code).to eq(401)
    end
  end
end
