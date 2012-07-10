module ApplicationHelper
  include KnockoutHelper

  def google_maps_javascript_include_tag
    javascript_include_tag(raw("http://maps.googleapis.com/maps/api/js?sensor=false&key=#{GoogleMapsKey}&v=3.7"))
  end

  def collection_admin?
    @collection_admin = current_user.admins?(collection) if @collection_admin.nil?
    @collection_admin
  end

  def render_hook(name, args = {})
  	result = ''
    Plugin.all.each do |plugin|
      plugin.hooks[name].each do |view|
        result << render(view, args)
      end
  	end
  	result.html_safe
  end
end
