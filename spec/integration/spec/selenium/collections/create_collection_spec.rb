require File.expand_path('../../../spec_helper', __FILE__)

acceptance_test do

it "should change collection icon", js:true do
  get "/"
  login_as "mmuller+9889@manas.com.ar", "123456789"
  find_element("Create Collection").click
  fill_in("collection_name") :with => "Colección de Prueba"
  click_button "Save"
  page.save_screenshot "Create Collection.png"
  page.should have_content("Collection Colección de prueba created")
end
