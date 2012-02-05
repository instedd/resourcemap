module ApplicationHelper
  def google_maps_javascript_include_tag
    javascript_include_tag(raw("http://maps.googleapis.com/maps/api/js?sensor=false&key=#{GoogleMapsKey}"))
  end

  def ko_link_to(text, click)
    link_to text, 'javascript:void()', 'data-bind' => "click: #{click}"
  end

  def ko_link_to_root(text, click)
    ko_link_to text, "$root.#{click}"
  end

  def ko_text_field_tag(name, options = {})
    text_field_tag name, '', ko(options.reverse_merge(:value => name, :valueUpdate => "'afterkeydown'"))
  end

  def ko_check_box_tag(name)
    check_box_tag name, '1', false, ko(:checked => name)
  end

  def ko(hash = {})
    {'data-bind' => kov(hash)}
  end

  def kov(hash = {})
    hash.map{|k, v| "#{k}:#{v}"}.join(',')
  end
end
