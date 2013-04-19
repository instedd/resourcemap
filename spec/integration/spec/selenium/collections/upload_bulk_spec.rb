 require File.expand_path('../../../spec_helper', __FILE__)

acceptance_test do
  
it "should change collection icon", js:true do
  create_collection = "Colección de Prueba"
  get "/"
  login_as "mmuller+9889@manas.com.ar", "123456789"
  page.find(:xpath, '//[@id="collections-main"]/div[1]/div[2]/table/tbody/tr[1]/td/button').click
  page.find(:xpath, '//[@id="collections-main"]/div[1]/div[1]/button[2]').click
  click_link "Upload it for bulk sites updates"
  find_element("Upload a CSV file to update multiple sites").click
  attach_file "sites", "Pesca_sites.csv"
  click_button "Upload" 
  end