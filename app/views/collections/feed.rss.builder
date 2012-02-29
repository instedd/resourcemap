xml.instruct! :xml, :version => "1.0" 
xml.rss :version => "2.0" do
  xml.channel do
    xml.title collection.name
    xml.link collection_url(collection)
    
    @sites.each do |site|
      xml.item do
        xml.title site.name
        xml.pubDate site.updated_at
        xml.link site_feed_url(site)
      end
    end
  end
end