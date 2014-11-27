# click all the span until we find the one we want to test

require 'spec_helper'

describe "change field values", :type => :request, uses_collections_structure: true do
  let (:user) do
    new_user
  end
  let(:date_escode) { multicollection_date_field.es_code }
  let(:identifier_escode) {multicollection_identifier_field.es_code}
  let(:old_value_for_select_one) {label_for_id(multicollection_select_one_field, old_values_for_fields['#select-one-input-selone'])}
  let(:new_value_for_select_one) {label_for_id(multicollection_select_one_field, new_values_for_fields['#select-one-input-selone'])}

  def old_values_for_fields
    {
        '#numeric-input-numeric' => '987654321',
        '#text-input-text' => 'before_changed',
        '#select-one-input-selone' => '1',
        "#date-input-#{date_escode}" => "12/15/2013",
        '#email-input-email' => "before@manas.com.ar",
        "#identifier-input-#{identifier_escode}" => '42',
        '#phone-input-phone' => '4444',
        '#site-input-site' => 'Second Site',
        '#user-input-user' => 'user2@manas.com.ar'
    }
  end

  def new_values_for_fields
    {
        '#numeric-input-numeric' => '1234567890',
        '#text-input-text' => 'after_changed',
        '#select-one-input-selone' => '2',
        "#date-input-#{date_escode}" => "12/15/2015",
        '#email-input-email' => "after@manas.com.ar",
        "#identifier-input-#{identifier_escode}" => '360',
        '#phone-input-phone' => '55555',
        '#site-input-site' => 'Third Site',
        '#user-input-user' => user.email
    }
  end

  def expect_old_values_and_edit
    all_span = page.all('span.value')
    for i in 3..all_span.count() - 1
        all_span[i].click
        if page.has_selector?(field_input_value)
            x = find(field_input_value)
        elsif page.has_selector?(field_select_value)
            x = find('select[id *= -input-]')
        end

        if x[:id] != "yes-no-input-yes_no"
            key = '#'+x[:id]
            expect(x.value).to eq(old_values_for_fields[key])
            if x[:id] == "select-one-input-selone"
                select(new_value_for_select_one, :from => x[:id])
            else
                fill_in x[:id], :with => new_values_for_fields[key]
                #Delete this if after fixing issue #807
                if x[:id] == "phone-input-phone"
                    all_span = go_back_and_refresh
                end
            end
        else
            all_span = go_back_and_refresh
            expect(all_span[i]).to have_content('yes')
            all_span[i].click
            find("#yes-no-input-yes_no").click
            click_button('OK')
        end
    end
  end

  def expect_new_values
    all_span = page.all('span.value')
    for i in 3..all_span.count() - 1
        all_span[i].click
        if page.has_selector?(field_input_value)
            x = find(field_input_value)
        elsif page.has_selector?(field_select_value)
            x = find('select[id *= -input-]')
        end

        if x[:id] != "yes-no-input-yes_no"
            key = '#'+x[:id]
            expect(x.value).to eq(new_values_for_fields[key])
            if x[:id] == "phone-input-phone"
                all_span = go_back_and_refresh
            end
        else
            all_span = go_back_and_refresh
            expect(all_span[i]).to have_content('no')
        end
    end
  end

  it "should edit site in edit mode", js:true do
    multicollection.memberships.create! :user_id => user.id, :admin => true
    s = multicollection.sites.make name: "Third Site", id: 3
    login_as(user)
    visit collections_path
    find(:xpath, first_collection_path).click
    find(:xpath, first_site_path).click

    date_escode = multicollection_date_field.es_code
    identifier_escode = multicollection_identifier_field.es_code

    click_link 'Edit Site'

    expect(find('#numeric-input-numeric').value).to eq(old_values_for_fields['#numeric-input-numeric'])
    expect(find('#text-input-text').value).to eq(old_values_for_fields['#text-input-text'])
    expect(page).to have_content(old_value_for_select_one)
    expect(find('#select-one-input-selone').value).to eq(old_values_for_fields['#select-one-input-selone'])
    expect(find("#date-input-#{date_escode}").value).to eq(old_values_for_fields["#date-input-#{date_escode}"])
    expect(find('#email-input-email').value).to eq(old_values_for_fields["#email-input-email"])
    expect(find("#identifier-input-#{identifier_escode}").value).to eq(old_values_for_fields["#identifier-input-#{identifier_escode}"])
    expect(find('#phone-input-phone').value).to eq(old_values_for_fields['#phone-input-phone'])
    expect(find('#site-input-site').value).to eq(old_values_for_fields['#site-input-site'])
    expect(find('#user-input-user').value).to eq(old_values_for_fields['#user-input-user'])

    fill_in 'numeric-input-numeric', :with => new_values_for_fields['#numeric-input-numeric']
    fill_in 'text-input-text', :with => new_values_for_fields['#text-input-text']
    select(new_value_for_select_one, :from => 'select-one-input-selone')
    fill_in "date-input-#{date_escode}", :with => new_values_for_fields["#date-input-#{date_escode}"]
    fill_in "email-input-email", :with => new_values_for_fields['#email-input-email']
    fill_in "identifier-input-#{identifier_escode}", :with => new_values_for_fields["#identifier-input-#{identifier_escode}"]
    fill_in "phone-input-phone", :with => new_values_for_fields['#phone-input-phone']
    fill_in "site-input-site", :with => new_values_for_fields['#site-input-site']
    fill_in "user-input-user", :with => new_values_for_fields['#user-input-user']
    click_button 'Done'

    click_link 'Edit Site'

    expect(find('#numeric-input-numeric').value).to eq(new_values_for_fields['#numeric-input-numeric'])
    expect(find('#text-input-text').value).to eq(new_values_for_fields['#text-input-text'])
    expect(find('#select-one-input-selone').value).to eq(new_values_for_fields['#select-one-input-selone'])
    expect(page).to have_content(new_value_for_select_one)
    expect(find("#date-input-#{date_escode}").value).to eq(new_values_for_fields["#date-input-#{date_escode}"])
    expect(find('#email-input-email').value).to eq(new_values_for_fields['#email-input-email'])
    expect(find("#identifier-input-#{identifier_escode}").value).to eq(new_values_for_fields["#identifier-input-#{identifier_escode}"])
    expect(find('#phone-input-phone').value).to eq(new_values_for_fields['#phone-input-phone'])
    expect(find('#site-input-site').value).to eq(new_values_for_fields['#site-input-site'])
    expect(find('#user-input-user').value).to eq(new_values_for_fields['#user-input-user'])
  end

  it "should edit site in single editing mode", js:true do
    multicollection.memberships.create! :user_id => user.id, :admin => true
    s = multicollection.sites.make name: "Third Site", id: 3
    login_as(user)

    visit collections_path
    find(:xpath, first_collection_path).click
    find(:xpath, first_site_path).click

    expect_old_values_and_edit

    go_back_and_refresh

    expect_new_values
  end

  it "should edit complex fields in edit mode", js:true do
    complex.memberships.create! :user_id => user.id, :admin => true
    login_as(user)
    visit collections_path
    find(:xpath, first_collection_path).click
    find(:xpath, first_site_path).click

    click_link 'Edit Site'
    x = find(container_element)
    expect(x).not_to have_content('One')
    expect(x).not_to have_content('Two')
    x.find('span[id = "Add more"]').click
    find('a', :text => 'One').click
    find('a', :text => 'Two').click

    expect(x).not_to have_content('child1')

    x.find('a > img').click
    find('span', :text => 'child1').click
    click_button 'Done'
    click_link 'Edit Site'
    x = find(container_element)
    expect(x).to have_content('child1')
    expect(x).to have_content('child2')
  end

end
