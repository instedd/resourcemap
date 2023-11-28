class Identity < ApplicationRecord
  belongs_to :user

  def assign_attributes(new_attributes)
    super ActiveSupport::HashWithIndifferentAccess.new(new_attributes).slice(
      :provider,
      :token,
      :user_id
    )
  end
end
