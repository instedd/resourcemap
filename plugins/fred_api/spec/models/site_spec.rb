require 'spec_helper'

describe Site do

	it "should generate random uuid if uuid is not supplied as parameter" do 
		site = Site.make
		site.uuid.should be
		(UUIDTools::UUID.parse site.uuid).should be_valid
	end

	it "should save supplied uuid on creation" do 
		uuid = UUIDTools::UUID.random_create.to_s
		site = Site.make_unsaved uuid: uuid
		site.should be_valid
		site.uuid.should eq(uuid)
	end

	it "should not save invalid uuid" do
		site = Site.make_unsaved uuid: "1234"
		site.should be_invalid
		site.errors.messages[:uuid].should include("is not valid")
	end

	it "should not change uuid" do
		site = Site.make
		site.uuid = "1234"
		site.should be_invalid
		site.errors.messages[:uuid].should include("cannot be changed once assigned")
	end

	it "should not create site with duplicated uuid through collection" do
		collection = Collection.make
		site2 = collection.sites.make 
		site = collection.sites.make_unsaved uuid: site2.uuid
		site.should be_invalid
		site.errors.messages[:uuid].should include("has already been taken")
	end

end