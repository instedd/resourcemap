require 'spec_helper'

describe MessagingController do
  describe "POST 'index'" do
    before(:each) do
      @params = { "guid" => "123", "from" => "sms://0", "body" => "foo" }
    end
    
    it "should save message" do
      Message.expects(:create!).with(:guid => "123", :from => "sms://0", :body => "foo")
      post :index, @params
    end

    describe "should validate post data" do
      def post_index_without(param)
        post :index, @params.clone.delete_if { |k| k == param.to_s }
      end

      it "should response error" do
        post :index
        response.response_code.should eq(400)
      end

      it "should check for guid" do
        post_index_without :guid
        response.body.should match /Validation failed: Guid can't be blank/
      end

      it "should check for from" do
        post_index_without :from
        response.body.should match /Validation failed: From can't be blank/
      end

      it "should check for body" do
        post_index_without :body
        response.body.should match /Validation failed: Body can't be blank/
      end
    end
    
    describe "message processing" do
      before(:each) do
        @message = Message.create @params
        controller.expects(:save_message).returns(@message)
      end
      
      it "should process message" do
        post :index, @params
        response.response_code.should == 200
      end

      it "should response plain text" do
        post :index, @params
        response.content_type.should == "text/plain"
      end
      
      it "should save error message as reply" do
        @message.expects(:process!).raises(RuntimeError, "An error occurred.")
        # Execute
        post :index, @params
        response.response_code.should == 200
        response.body.should =~ /An error occurred./
      end
    end
  end
  
  describe "authenticate" do
    it "should authenticate via http basic authentication" do
      post :authenticate
      response.response_code.should == 401
    end
    
    it "should response unauthorized for bad user" do
      request.env["HTTP_AUTHORIZATION"] = ActionController::HttpAuthentication::Basic.encode_credentials("foo", "secret")
      post :authenticate
      response.response_code.should == 401
    end
  end

  describe "GET 'index'" do
    it "should response error for GET request" do
      get :index
      response.response_code.should eq(400)
      response.body.should match /The HttpVerb you are using is not supported./
    end
  end

end
