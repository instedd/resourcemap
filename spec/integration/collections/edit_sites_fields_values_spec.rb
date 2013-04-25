require 'spec_helper' 

describe "collections" do 
 
  it "should edit site field values", js:true do   
    
    current_user = User.make(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
    collection = create_collection_for (current_user)
    layer = create_layer_for (collection)
    text = layer.text_fields.make(:name => 'Text', :code => 'text')
    phone = layer.phone_fields.make(:name => 'Phone', :code => 'phone')
    email = layer.email_fields.make(:name => 'Email', :code => 'email')
    numeric = layer.numeric_fields.make(:name => 'Numeric', :code => 'numeric')
    user_field = layer.user_fields.make(:name => 'User', :code => 'user')
    select_one = layer.select_one_fields.make(:name => 'Select One', :code => 'selone', config: {"options"=>[{"id"=>1, "code"=>"option code 1", "label"=>"first option"},{"id"=>2, "code"=>"option code 2", "label"=>"second option"}], "next_id"=>3})
    select_many = layer.select_many_fields.make(:name => 'Select Many', :code => 'selmany', config: {"options"=>[{"id"=>1, "code"=>"firstopcod", "label"=>"first op"}, {"id"=>2, "code"=>"secopcod", "label"=>"second op"}, {"id"=>3, "code"=>"anotheropcod", "label"=>"another op"}], "next_id"=>4})
    yes_no = layer.yes_no_fields.make(:name => 'Yes No', :code => 'y/n')
    identifier = layer.identifier_fields.make(:name => 'ID', :code => 'id')
    date = layer.date_fields.make(:name => 'Date', :code => 'date')
    site = layer.site_fields.make(:name => 'Site', :code => 'site')
    site1 = collection.sites.make properties: { text.es_code => 'one text' }
    collection.sites.make properties: { numeric.es_code => 'no' }
    collection.sites.make properties: { phone.es_code => '1558769876' }
    collection.sites.make properties: { email.es_code => 'man@as.com' }
    collection.sites.make :name => 'Type: User', properties: { user_field.es_code => 'John' }
    collection.sites.make :name => 'Type: Select One', properties: { select_one.es_code => 2 }
    collection.sites.make :name => 'Type: Select Many', properties: { select_many.es_code => [2,3] }
    collection.sites.make properties: { yes_no.es_code => 1 }
    collection.sites.make properties: { identifier.es_code => 'ID4567HJL' }
    collection.sites.make :name => 'Type: Site', properties: { site.es_code => site1.name }
    collection.sites.make :name => 'Type: Date', properties: { date.es_code => '2013-07-15'}
    login_as (current_user)
    visit collections_path
    sleep 30
  end

end