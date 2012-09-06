module Collection::SiteMembershipConcerns
  extend ActiveSupport::Concern

  included do
    has_many :site_memberships, dependent: :destroy
  end
end
