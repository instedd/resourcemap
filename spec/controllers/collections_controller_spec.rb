require 'spec_helper'

describe CollectionsController do
  include Devise::TestHelpers
  render_views

  let!(:user) { User.make }
  let!(:collection) { user.create_collection(Collection.make) }

  before(:each) {sign_in user}


  it "should generate error description list form preprocessed hierarchy list" do
    hierarchy_csv = [
      {:order=>1, :error=>"Wrong format.", :error_description=>"Invalid column number"},
      {:order=>2, :id=>"2", :name=>"dad", :sub=>[{:order=>3, :id=>"3", :name=>"son"}]} ]

    res = CollectionsController.generate_error_description_list(hierarchy_csv)

    res.should == ["Error: Wrong format. Invalid column number in line 1"]
  end

  it "should generate error description list form invalid hierarchy list" do
    hierarchy_csv = [{:error=>"Illegal quoting in line 3."}]

    res = CollectionsController.generate_error_description_list(hierarchy_csv)

    res.should == ["Error: Illegal quoting in line 3."]
  end

end
