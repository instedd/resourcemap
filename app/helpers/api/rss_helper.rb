module Api::RssHelper

  def collection_rss(xml, collection)
    xml.rss specification do
      xml.channel do
        xml.title collection.name

        collection.sites.order('updated_at DESC').each do |site|
          site_item_rss xml, site
        end
      end
    end
  end

  def site_item_rss(xml, site)
    xml.item do
      xml.title site.name
      xml.pubDate site.updated_at
      xml.link api_site_url(site, format: :rss)
      xml.geo :lat ,site.lat
      xml.geo :long, site.lng

      site.properties.each do |code, value|
        property_rss xml, code, value
      end
    end
  end

  def property_rss(xml, code, value)
    xml.rm :property do
      xml.code code
      xml.value value
    end
  end


  private

  def specification
    {
      'version'   => "2.0",
      'xmlns:geo' => "http://www.w3.org/2003/01/geo/wgs84_pos#", 
      'xmlns:rm'  => "http://resourcemap.instedd.org/api/1.0"
    }
  end

end
