module Site::PrefixConcern
  extend ActiveSupport::Concern

  included do
    before_create :assign_id_with_prefix
  end

  def assign_id_with_prefix
    self.id_with_prefix = generate_id_with_prefix if self.id_with_prefix.nil?
  end

  def generate_id_with_prefix
    site = Site.where('id_with_prefix is not null').find_last_by_collection_id(self.collection_id)
    if site.nil?
      id_with_prefix = [Prefix.next.version,1]
    else
      id_with_prefix = site.get_id_with_prefix
      id_with_prefix[1].next!
    end
    id_with_prefix.join
  end

  def get_id_with_prefix
    assign_id_with_prefix unless id_with_prefix
    self.id_with_prefix.split /(\d+)/
  end
end
