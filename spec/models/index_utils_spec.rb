require 'spec_helper'
describe Site::IndexUtils do
  let!(:user) { User.make }
  let!(:collection) { user.create_collection Collection.make_unsaved }
  let!(:site) {collection.sites.make :name => 'site_01'} 
  
  it 'should search site by site.id_with_prefix' do
    search = collection.new_search
    search.id site.id
    search.results.first['_source']["id_with_prefix"].should eq site.id_with_prefix
  end
end

