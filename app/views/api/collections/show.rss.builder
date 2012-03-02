xml.instruct! :xml, :version => "1.0" 
xml.rss :version => "2.0" do
  xml.channel do
    xml.title collection.name
    xml.link collection_url(collection)
    
    collection.sites.order('updated_at DESC').each do |site|
      xml.item do
        xml.title site.name
        xml.pubDate site.updated_at
        xml.link api_site_url(site, format: :rss)
      end
    end
  end
end
