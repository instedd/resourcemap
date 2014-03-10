class GuestUser < User
  def initialize
    @is_guest = true
  end

  def readable_layer_ids
    Layer.where(anonymous_user_permission:"read").map { |l| l.id }
  end
end
