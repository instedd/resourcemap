require 'spec_helper'
require 'elastic_search/query_helper.rb'

describe ElasticSearch::QueryHelper do
  let!(:collection) { Collection.make }

  it 'appends wildcard to number queries' do
    query = ElasticSearch::QueryHelper.full_text_search '34', nil, collection

    query.last.should end_with('*')
  end
end
