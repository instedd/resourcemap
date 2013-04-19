require File.expand_path('../../../spec_helper', __FILE__)

acceptance_test do

it "should change collection icon", js:true do
  login_as "mmuller+9889@manas.com.ar", "123456789"
  create_collection :name => "Colección de Prueba"
  page.find(:xpath, '//[@id="collections-main"]/div[1]/div[2]/table/tbody/tr[1]/td/button').click
  click_button "Create Site"
  fill_in "name", :with => "New site"
  fill_in "locationText", :with => '-34.682982, -58.437048'
  click_button "Done"
  page.save_screenshot "Create Site"
  page.should have_content("Site 'New site' successfully created")
end
