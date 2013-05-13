require 'spec_helper' 

describe "collections" do 
 
it "should switch snapshots", js:true do

    user = User.make(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
    collection = create_collection_for(user) 
    snapshots = %w{ jan feb march april may }  
    snapshots.each do |snapshot|
      snap= Snapshot.make :collection => collection, :name => snapshot
      UserSnapshot.make :user => user, :snapshot => snap
    end 
    login_as (user)
    visit collections_path
    page.find(:xpath, '//div[@id="collections-main"]/div[1]/div[2]/table/tbody/tr/td/div[2]/button').click
    page.find(:xpath, '//div[@id="collections-main"]/div[1]/div[1]/button[2]').click
    sleep 3
    choose ('name_feb')
    sleep 3
    page.should have_content 'Snapshot feb loaded'
    page.save_screenshot "Switch_snapshot.png"
    
  end

end
