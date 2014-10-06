require 'spec_helper'

describe Site, :type => :model do

	it "should generate random uuid if uuid is not supplied as parameter" do 
		site = Site.make
		expect(site.uuid).to be
		expect(UUIDTools::UUID.parse site.uuid).to be_valid
	end

	it "should save supplied uuid on creation" do 
		uuid = UUIDTools::UUID.random_create.to_s
		site = Site.make_unsaved uuid: uuid
		expect(site).to be_valid
		expect(site.uuid).to eq(uuid)
	end

	it "should not save invalid uuid" do
		site = Site.make_unsaved uuid: "1234"
		expect(site).to be_invalid
		expect(site.errors.messages[:uuid]).to include("is not valid")
	end

	it "should not change uuid" do
		site = Site.make
		site.uuid = "1234"
		expect(site).to be_invalid
		expect(site.errors.messages[:uuid]).to include("cannot be changed once assigned")
	end

	it "should not create site with duplicated uuid through collection" do
		collection = Collection.make
		site2 = collection.sites.make 
		site = collection.sites.make_unsaved uuid: site2.uuid
		expect(site).to be_invalid
		expect(site.errors.messages[:uuid]).to include("has already been taken")
	end

end