require 'spec_helper'
require 'elastic_search/query_helper.rb'

describe ElasticSearch::QueryHelper do
  let!(:collection) { Collection.make }

  it 'does not append wildcard to integer queries' do
    query = ElasticSearch::QueryHelper.full_text_search '34', nil, collection
    query.last.should_not end_with('*')
  end

  it 'appends wildcard to decimal queries' do
    query = ElasticSearch::QueryHelper.full_text_search '34.9', nil, collection
    query.last.should end_with('*')
    query = ElasticSearch::QueryHelper.full_text_search '-34.9', nil, collection
    query.last.should end_with('*')
  end

  it 'does not append wildcard to separate words queries' do
    query = ElasticSearch::QueryHelper.full_text_search 'one two', nil, collection
    query.last.should_not end_with('*')
  end
end
