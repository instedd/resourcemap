require 'spec_helper' 

describe "change_password_fail" do 
 
it " should not change password", js:true do
    @user = User.make(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
    @collection = create_collection_for(@user) 
    login_as (@user)
    visit collections_path
    sleep 2
    find(:xpath, '//div[@id="toolbar"]/ul[2]/li[2]/a').click
    within "form#edit_user" do 
      fill_in "user_current_password", :with => @user.password
      fill_in "user_password", :with => 'dexmor.15'      
    end
    click_button 'Update'
    sleep 1
    page.save_screenshot 'Change_password_fail.png'
    page.should have_content "Password doesn't match confirmation"
  end
end
