require 'spec_helper' 

describe "members" do 
 
it "should give admin rights", js:true do
    admin = User.make(:email => 'admin@admin.com')
    collection = create_collection_for(admin) 
    user = User.make(:email => 'member@member.com')
    user.memberships.make collection: collection, admin: false
    login_as (user)
    visit collections_path
    #this user cannot see the Members tab
    login_as (admin)
    visit collections_path
    #this user can see the Members tab
    #go to the members tab and give admin rights to the another user
    login_as (user)
    visit collections_path
    #NOW this user SHOULD see the Members tab
  end
  
end
