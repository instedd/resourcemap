class Collection
  property! id, name
  property fields :: Array(Field)

  def initialize
    @fields = [] of Field
  end

  def self.find(id, visible_field_ids)
    res = self.new

    Database.instance.execute("SELECT id, name FROM collections WHERE id=#{id} LIMIT 1").each_row do |row|
      res.id = row[0] as Int32
      res.name = row[1] as String
    end

    res.fields = Field.where({collection_id: id, id: visible_field_ids})

    res
  end

  def field_by_id(field_id)
    fields.select { |f| f.id == field_id }.first?
  end

  def field_by_code(field_code)
    fields.select { |f| f.code == field_code }.first
  end
end
