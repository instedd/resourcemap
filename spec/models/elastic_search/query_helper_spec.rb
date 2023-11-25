require 'spec_helper'
require 'elastic_search/query_helper.rb'

describe ElasticSearch::QueryHelper, :type => :model do
  let(:collection) { Collection.make }

  it 'does not append wildcard to integer queries' do
    query = ElasticSearch::QueryHelper.full_text_search '34', nil, collection
    expect(query.last).not_to end_with('*')
  end

  it 'appends wildcard to decimal queries' do
    query = ElasticSearch::QueryHelper.full_text_search '34.9', nil, collection
    expect(query.last).to end_with('*')
    query = ElasticSearch::QueryHelper.full_text_search '-34.9', nil, collection
    expect(query.last).to end_with('*')
  end

  it 'does not append wildcard to separate words queries' do
    query = ElasticSearch::QueryHelper.full_text_search 'one two', nil, collection
    expect(query.last).not_to end_with('*')
  end

  it 'appends wildcard to one word queries' do
    query = ElasticSearch::QueryHelper.full_text_search 'one', nil, collection
    expect(query).to eq('one*')
  end

  it 'does not append wildcard to luhn numbers' do
    query = ElasticSearch::QueryHelper.full_text_search '100000-4', nil, collection
    expect(query).to eq('100000\\-4')
  end
end
