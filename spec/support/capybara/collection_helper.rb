module Capybara::CollectionHelper

  def create_collection_for(user)
    collection = user.collections.make name: 'Central Hospital'
    user.memberships.make collection: collection, admin: true
    collection
  end

  def create_site_for(collection, site_name="Health Center")
    collection.sites.make(:name => site_name, :lng => 14.3574, :lat => 26.7574)
  end

  def create_layer_for(collection)
    collection.layers.make(:name => 'Central Hospital Layer 1')
  end

  def create_field_for (layer)
  	layer.text_fields.make(:name => 'Central Hospital Layer 1 Field', :code => 'CHL1F')
  end

  def first_collection_path
    '//div[@id="collections-main"]/div[1]/div[2]/table/tbody/tr[1]/td/button'
  end

  def back_to_collections_button
    find('button.pback').path
  end

  def back_to_sites_button
    find('button.pback').path
  end

  def first_site_path
    '//div[@id="collections-main"]/div[1]/div[2]/table/tbody/tr[1]/td/button'
  end

  def collection_has_logo?
    page.has_selector?('#collection-logo')
  end

  def collection_with_name_link(name)
    find('a', text: name).path
  end

  def collection_configuration_button
    find('#collections-main button.fconfiguration').path
  end

  def label_for_id(element, id)
    x = element[:config]["options"].detect { |f| f["id"] == id }
    x["label"]
  end

  def field_input_value
    'input[id *= "-input-"]'
  end

  def field_select_value
    'select[id *= "-input-"]'
  end

  def go_back_and_refresh
    find('button.pback').click
    find(:xpath, first_site_path).click
    page.all('span.value')
  end

  def container_element
    'div.tablescroll'
  end

  def first_last_update_path
    '//*[@id="collections-main"]/div[2]/div/div[2]/table/tbody/tr[1]/td[4]'
  end

  def create_collection_link
    '//div[@id="collections-main"]/div[1]/div[3]/button'
  end

  def breadcrumb_collection_link
    '//div[@class="BreadCrumb"]/ul/li[1]/a'
  end

  def expand_advanced_options
    find('img.members-collapse-icon').click
  end

  def edit_layer_button
    '//div[@id="layers-main"]/div[2]/button'
  end

  def no_member_email
    '//div[@id="autocomplete_container"]/ul/li/a'
  end

  def expand_name
    '//div[@class="refine-popup box"]/div[3]'
  end

  def fill_starts_with(name)
    find(:xpath, '//div[@class="refine-popup box"]/div[4]/input').set(name)
  end

  def expand_member_settings
    find(:xpath, '//div[@id="memberPermissionsTable"]/table/tbody/tr[5]/td/div/div[1]/img').click
  end

  def confirm_remove_member
    find('a', :text => 'Confirm').click
  end

  def access_denied_message
     "The page you are trying to access doesn't exist or you don't have permission for accessing it. Contact the administrator if you think you should."
  end
end
