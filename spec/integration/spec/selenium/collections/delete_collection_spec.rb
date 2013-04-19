require File.expand_path('../../../spec_helper', __FILE__)

acceptance_test do

it "should change collection icon", js:true do
  get "/"
  login_as "mmuller+9889@manas.com.ar", "123456789"
  create_collection :name => "Colección de Prueba"
  page.find(:xpath, '//[@id="collections-main"]/div[1]/div[2]/table/tbody/tr[1]/td/button').click
  page.find(:xpath, '//[@id="collections-main"]/div[1]/div[1]/button[2]').click
  click_link "Delete Collection"
  click_button "Confirm"
  page.save_screenshot "Delete Collection.png"
  page.should have_content "Collection Colección de Prueba deleted"
end
