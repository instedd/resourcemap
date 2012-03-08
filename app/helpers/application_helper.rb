module ApplicationHelper
  include KnockoutHelper

  def google_maps_javascript_include_tag
    javascript_include_tag(raw("http://maps.googleapis.com/maps/api/js?sensor=false&key=#{GoogleMapsKey}"))
  end
end
