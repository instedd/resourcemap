module Collection::SiteMembershipsConcern
  extend ActiveSupport::Concern

  included do
    has_many :site_memberships, dependent: :destroy
    alias_method_chain :visible_fields_for, :site_memberships
  end

  def visible_fields_for_with_site_memberships(user, options = {})
    layers = visible_fields_for_without_site_memberships(user, options)
    return layers unless site_memberships_plugin_enabled?

    hash = {sites: {view: {_all: true}, update: {_all: false, ids: [2]}}}
    layers.map do |layer|
      layer.update hash
    end
  end
end
