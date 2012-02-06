class Hash
  def fetch_many(*keys)
    keys.map{|key| self[key]}
  end
end
