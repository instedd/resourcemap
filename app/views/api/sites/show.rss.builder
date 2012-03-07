xml.instruct! :xml, version: "1.0"
xml.rss rss_specification do
  xml.channel do
    xml.title site.name

    site_item_rss xml, @result
  end
end
