require 'spec_helper'

describe ElasticSearchSitesAdapter do
  it "adapts one site" do
    listener = mock('listener')
    listener.should_receive(:add).with(181984, -37.55442222700955, 136.5797882218185)

    adapter = ElasticSearchSitesAdapter.new listener
    adapter.parse %(
      {
        "took" : 20,
        "timed_out" : false,
        "_shards" : {
          "total" : 55,
          "successful" : 55,
          "failed" : 0
        },
        "hits" : {
          "total" : 4,
          "max_score" : 1.0,
          "hits" : [ {
            "_index" : "collection_63",
            "_type" : "site",
            "_id" : "181984",
            "_score" : 1.0, "_source" : {"id":181984,"type":"site","location":{"lat":-37.55442222700955,"lon":136.5797882218185},"properties":{"beds":84,"vaccines":75,"patients":61}}
          } ]
        }
      }
    )
  end

  it "adapts two sites" do
    listener = mock('listener')
    listener.should_receive(:add).with(181984, -37.55442222700955, 136.5797882218185)
    listener.should_receive(:add).with(181985, -47.55442222700955, 137.5797882218185)

    adapter = ElasticSearchSitesAdapter.new listener
    adapter.parse %(
      {
        "took" : 20,
        "timed_out" : false,
        "_shards" : {
          "total" : 55,
          "successful" : 55,
          "failed" : 0
        },
        "hits" : {
          "total" : 4,
          "max_score" : 1.0,
          "hits" : [ {
            "_index" : "collection_63",
            "_type" : "site",
            "_id" : "181984",
            "_score" : 1.0, "_source" : {"id":181984,"type":"site","location":{"lat":-37.55442222700955,"lon":136.5797882218185},"properties":{"beds":84,"vaccines":75,"patients":61}}
          }, {
            "_index" : "collection_63",
            "_type" : "site",
            "_id" : "181984",
            "_score" : 1.0, "_source" : {"id":181985,"type":"site","location":{"lat":-47.55442222700955,"lon":137.5797882218185},"properties":{"beds":84,"vaccines":75,"patients":61}}
          } ]
        }
      }
    )
  end
end
