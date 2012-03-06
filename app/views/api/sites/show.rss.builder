xml.instruct! :xml, version: "1.0"
xml.rss version: "2.0" do
  xml.channel do
    xml.title site.name
    xml.link api_site_url(site)

    site.properties.each do |code, value|
      xml.item do
        xml.title site.collection.fields.find_by_code(code).name
        xml.description value
      end
    end
  end
end
